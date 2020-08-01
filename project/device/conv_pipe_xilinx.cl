/*
 * ------------------------------------------------------
 *
 *   PipeCNN: An OpenCL-Based FPGA Accelerator for CNNs
 *
 * ------------------------------------------------------
 * Filename:
 *   - conv_pipe.cl
 *
 * Author(s):
 *   - Dong Wang, wangdong@m.bjtu.edu.cn
 *
 * History:
 *   - v1.3 Win-Buffer-Based Implementation
 * ------------------------------------
 *
 *   Copyright (C) 2019, Institute of Information Science,
 *   Beijing Jiaotong University. All rights reserved.
 *
 *   Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 *   You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *   Unless required by applicable law or agreed to in writing, software
 *   distributed under the License is distributed on an "AS IS" BASIS,
 *   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *   See the License for the specific language governing permissions and
 *   limitations under the License.
 *
 */

// The following macros are used for debug
//#define DEBUG_MEMRD
//#define DEBUG_CONV
//#define DEBUG_BN
//#define DEBUG_POOL
//#define DEBUG_MEMWR
//#define DEBUG_LRN
//#define DEBUG_LRN_OUT

#include "hw_param.cl"
#include "pipe.cl" // for xilinx, the channels are defined here by using pipes

pipe bool pool_sync_ch __attribute__((xcl_reqd_pipe_depth(32)));
#define pool_sync_ch_write_pipe_block(input_data) { bool temp; \
                                                    temp = input_data; \
                                                    write_pipe_block(pool_sync_ch, &temp); }
#define pool_sync_ch_read_pipe_block(input_data)  { bool temp; \
                                                    read_pipe_block (pool_sync_ch, &temp);\
                                                    input_data = temp;}

// Define the precision of the data-path
typedef char DPTYPE;
typedef int  MACTYPE;

// Vectorized data type
typedef struct {
    DPTYPE data[VEC_SIZE];
} lane_data;

// Combined vec-data type from multiple lane
typedef struct {
    lane_data lane[LANE_NUM];
} channel_vec;

// Combined scalar data type from multiple lane
typedef struct {
    DPTYPE lane[LANE_NUM];
} channel_scal;


// parallel MAC units including (VEC_SIZE-1) multipliers
__attribute__((always_inline))
MACTYPE mac(lane_data input, lane_data weights)
{
    MACTYPE output = MASK_MULT & CZERO;

    __attribute__((opencl_unroll_hint))
    for(int i=0; i<VEC_SIZE; i++) {
        output += input.data[i]*weights.data[i];
    }
    return output;
}

__attribute__((always_inline))
DPTYPE pool_max(DPTYPE a_in, DPTYPE b_in)
{
    DPTYPE max_value;

    if(a_in >= b_in)
        max_value = a_in;
    else
        max_value = b_in;

    return max_value;

}

// Fetch Data from Global Memory
__kernel
__attribute__((reqd_work_group_size(1,1,1)))
//__attribute__((xcl_dataflow))
void memRead(
    // Params Ports
    uchar  data_dim1,
    uchar  data_dim2,
    ushort data_dim1xdim2,
    uchar  weight_dim1,
    uchar  weight_dim2,
    ushort weight_dim3,
    ushort weight_dim4_div_lane, // avoid generating divider
    uchar  weight_dim1x2,
    uint   weight_dim1x2x3,
    uchar  conv_x,
    //uchar  conv_y,           // not used in this version
    uchar  stride,
    uchar  padding,
    uchar  split,
    uchar  group_num_x,
    uchar  group_num_y,
    uchar  group_rem_size_x,
    //uchar  group_rem_size_y, // not used in this version
    uint   group_rem_size_xyz,
    uchar  win_size_x,
    uchar  win_size_y,
    uint   win_size_xyz,
    // Data Ports
    __global lane_data    *restrict bottom,   //__attribute__((xcl_data_pack(bottom))),
    __global channel_vec  *restrict weights,  //__attribute__((xcl_data_pack(weights))),
    __global channel_scal *restrict bias   )  // __attribute__((xcl_data_pack(bias)))    )

{


    // Input Data, Weights and Bias
    lane_data     data_vec;
    channel_vec   data_ch_vec;
    channel_vec   weight_ch_vec;
    channel_scal  bias_ch_in;
    ushort        data_offset = 0; // assuming the 1st layer is not in split

    // virtual loop counters
    ushort gp_num_x, gp_num_y, out_idx_z;
    ushort gp_num_x_winbuf, gp_num_y_winbuf, out_idx_z_winbuf;
    uchar  output_idx_dim1, output_idx_dim2;
    ushort output_idx_dim3;
    uchar  win_itm_x, win_itm_y;
    ushort win_itm_z;

    uchar  gp_item_idx_x;

    ushort feature_idx_dim1, feature_idx_dim2;
    ushort feature_idx_dim3;

    uint   item_loop_bound;

    uchar  flag; // ping-pong flag

    // Ping-pong buffer
    __local lane_data    win_buffer[2][WIN_BUF_SIZE]  __attribute__((xcl_array_partition(complete,1))); // working sequence 0->1->0->1 ...
    // Weight buffer
    __local channel_vec  weight_buffer[WEIGHT_BUF_SIZE];

Init:// Initialize the winbuf with the data in the first iteration of the group looping (as gp_num_x_winbuf=0, gp_num_y_winbuf=0)
    for(unsigned short win_itm_z=0; win_itm_z<weight_dim3/VEC_SIZE; win_itm_z++){
        for(unsigned char  win_itm_y=0; win_itm_y<win_size_y; win_itm_y++){
            for(unsigned char  win_itm_x=0; win_itm_x<win_size_x; win_itm_x++){

                feature_idx_dim1 = win_itm_x;
                feature_idx_dim2 = win_itm_y;
                feature_idx_dim3 = win_itm_z;

                // fetch feature map for the current group and caching in win buffer
                if((feature_idx_dim1>=padding && feature_idx_dim1<data_dim1+padding) && (feature_idx_dim2>=padding && feature_idx_dim2<data_dim2+padding)){

                    data_vec = bottom[data_offset*data_dim1xdim2 + feature_idx_dim3*data_dim1xdim2 + (feature_idx_dim2-padding)*data_dim1 + (feature_idx_dim1-padding)];
                }
                else{ // for padding (feature_idx<padding or data_dim+padding<=feature_idx<data_dim+2*padding)
				// or invalid work-item in the last group set feature map to zeros (feature_idx>=data_dim+2*padding)
                    __attribute__((opencl_unroll_hint))
                    for(unsigned char vv=0; vv<VEC_SIZE; vv++){
                        data_vec.data[vv] = CZERO;
                    }
                }

                // start from using buffer[0]
                win_buffer[0][win_itm_z*win_size_y*win_size_x + win_itm_y*win_size_x + win_itm_x] = data_vec;
            
            }
        }
    }

    // reset group virtual loop counters for winbuf loading operations
	// the gp loop counter for winbuf starts one iteration earlier than global group virtual loop counter
	// in this iteration, the winbuf is pre-initialized as previous loops shows
    if(group_num_x==1 && group_num_y==1){
        gp_num_x_winbuf = 0; // there is only one group for FC mode when batch=1
        gp_num_y_winbuf = 0;}
    else if(group_num_x==1){
		gp_num_x_winbuf = 0; // special case for convolution layers with weight_dim1/2=1, such as resnet50
		gp_num_y_winbuf = 1;}
	else{
		gp_num_x_winbuf = 1; // loop start from the second group for normal convolution layers
		gp_num_y_winbuf = 0;}

    out_idx_z_winbuf = 0;

    // reset global group virtual loop counters
    gp_num_x = 0;
    gp_num_y = 0;
    out_idx_z = 0;

Group:for(unsigned int out_idx_xyz=0; out_idx_xyz<(weight_dim4_div_lane*group_num_y*group_num_x); out_idx_xyz++){
	// The following group loops are flattened as the upper loop to improve pipeline efficiency
	//for(unsigned short out_idx_z=0; out_idx_z<weight_dim4_div_lane; out_idx_z++){

		// special case when split==1, the output feature maps depend on only half the input feature maps
        if(split==0)
            data_offset = 0;
        else if(out_idx_z_winbuf<(weight_dim4_div_lane>>1)) // the lower half of the output feature maps depend on the lower half of the input
            data_offset = 0;
        else
            data_offset = weight_dim3/VEC_SIZE;	// the upper half of the output feature maps depend on the upper half of the input

		//for(unsigned short gp_num_y=0; gp_num_y<group_num_y; gp_num_y++){
			//for(unsigned short gp_num_x=0; gp_num_x<group_num_x+1; gp_num_x++){ // add one more extra iteration for ping-pong buffering operations

                flag = out_idx_xyz & 0x01; //ping-pong flag

                // reset output loop counters
                output_idx_dim1 = 0;
                output_idx_dim2 = 0;
                output_idx_dim3 = 0;
                // reset in-group item counters
                gp_item_idx_x = 0;

                // reset input winbuffer loop counters
                win_itm_x = 0;
                win_itm_y = 0;
                win_itm_z = 0;


                if(gp_num_x==group_num_x-1) // last group in each row
                    // ensuring that both winbuf load loop and output loop are finished, i.e., use a larger value as the loop bound
                    item_loop_bound = win_size_x>=group_rem_size_x?(win_size_xyz/VEC_SIZE):(group_rem_size_xyz/VEC_SIZE);
                else{
                        if(stride>=weight_dim1 || stride>=weight_dim2) // special case convolution layers with stride>weight_dim1/2, such as resnet50
                            item_loop_bound = win_size_xyz/VEC_SIZE;
                        else
                            item_loop_bound = (weight_dim1x2x3*CONV_GP_SIZE_Y*CONV_GP_SIZE_X/VEC_SIZE);
                }

                //#pragma ivdep array(win_buffer)
                //#pragma ivdep array(weight_buffer)
                //#pragma ivdep
                Item:for(unsigned int  win_itm_xyz=0; win_itm_xyz<item_loop_bound; win_itm_xyz++){
                //// The following loops are flattened as the upper loop to improve pipeline efficiency
                //for(unsigned short win_itm_z=0; win_itm_z<weight_dim3/VEC_SIZE; win_itm_z++){
                //	for(unsigned char  win_itm_y=0; win_itm_y<weight_dim2*CONV_GP_SIZE_Y; win_itm_y++){
                //		for(unsigned char  win_itm_x=0; win_itm_x<weight_dim1*CONV_GP_SIZE_X; win_itm_x++){

                            // Winbuffer loading operations
                            if(win_itm_z<weight_dim3/VEC_SIZE){

                                feature_idx_dim1 = win_itm_x+gp_num_x_winbuf*CONV_GP_SIZE_X*stride;
                                feature_idx_dim2 = win_itm_y+gp_num_y_winbuf*CONV_GP_SIZE_Y*stride;
                                feature_idx_dim3 = win_itm_z;

                                // fetch feature map for the current group and caching in win buffer
                                if((feature_idx_dim1>=padding && feature_idx_dim1<data_dim1+padding) && (feature_idx_dim2>=padding && feature_idx_dim2<data_dim2+padding)){

                                    data_vec = bottom[data_offset*data_dim1xdim2 + feature_idx_dim3*data_dim1xdim2 + (feature_idx_dim2-padding)*data_dim1 + (feature_idx_dim1-padding)];
                                }
                                else{ // for padding (feature_idx<padding or data_dim+padding<=feature_idx<data_dim+2*padding)
                                    // or invalid work-item in the last group set feature map to zeros (feature_idx>=data_dim+2*padding)
                                    __attribute__((opencl_unroll_hint))
                                    for(unsigned char vv=0; vv<VEC_SIZE; vv++){
                                        data_vec.data[vv] = CZERO;
                                    }
                                }

                                win_buffer[(~flag)&0x01][win_itm_z*win_size_y*win_size_x + win_itm_y*win_size_x + win_itm_x] = data_vec;
                                
                                // used as loop counters
                                if((win_itm_z==weight_dim3/VEC_SIZE-1) && (win_itm_y==win_size_y-1) && (win_itm_x==win_size_x-1))
                                    win_itm_z = 0;
                                else if((win_itm_y==win_size_y-1) && (win_itm_x==win_size_x-1))
                                    win_itm_z++;

                                if((win_itm_y==win_size_y-1) && (win_itm_x==win_size_x-1))
                                    win_itm_y = 0;
                                else if(win_itm_x==win_size_x-1)
                                    win_itm_y++;

                                if(win_itm_x==win_size_x-1)
                                    win_itm_x = 0;
                                else
                                    win_itm_x++;

                            }

                            // Load weight into weight buffer
                            if(gp_item_idx_x==0){

                                weight_ch_vec = weights[out_idx_z*weight_dim1x2x3/VEC_SIZE + output_idx_dim3*weight_dim1x2 + output_idx_dim2*weight_dim1 + output_idx_dim1];
                                weight_buffer[output_idx_dim3*weight_dim2*weight_dim1 + output_idx_dim2*weight_dim1 + output_idx_dim1] = weight_ch_vec;
                        
                            }

                            // Only output data for valid convolution work-items
                            // In this version, grouping is only performed in row (x) direction
                            if(gp_num_x*CONV_GP_SIZE_X+gp_item_idx_x<conv_x){

                                if(output_idx_dim1==0 && output_idx_dim2==0 && output_idx_dim3==0){
                                    bias_ch_in = bias[out_idx_z];
                                    bias_ch_write_pipe_block(bias_ch_in);
                                    //#ifdef DEBUG_MEMRD
                                    //printf("work-item x=%d, y=%d, z=%d, channel =0, write bias=%d\n", output_idx_dim1, output_idx_dim2, output_idx_dim3, bias_ch_in.lane[0]);
                                    //#endif
                                }

                                // data
                                data_vec = win_buffer[flag][output_idx_dim3*win_size_y*win_size_x + output_idx_dim2*win_size_x + (output_idx_dim1+gp_item_idx_x*stride)];
                                __attribute__((opencl_unroll_hint))
                                for(unsigned char ll=0; ll<LANE_NUM; ll++){
                                    data_ch_vec.lane[ll] = data_vec;
                                }
                                data_write_pipe_block(data_ch_vec);


                                // weight and bias fetcher
                                weight_ch_vec = weight_buffer[output_idx_dim3*weight_dim2*weight_dim1 + output_idx_dim2*weight_dim1 + output_idx_dim1];
                                weight_write_pipe_block(weight_ch_vec);

                                #ifdef DEBUG_MEMRD
                                //if(gp_num_x==group_num_x-1 && gp_num_y==0 && out_idx_z==0){
                                    //printf("work-item x=%d, y=%d, z=%d, offset=%d, write data in channel 0=%f\n", output_idx_dim1, output_idx_dim2, output_idx_dim3, data_offset, (float)data_ch_vec.lane[0].data[0]);
                                    printf("work-item x=%d, y=%d, z=%d, write weight in channel 0=%f\n", output_idx_dim1, output_idx_dim2, output_idx_dim3, (float)weight_ch_vec.lane[0].data[0]);
                                //}
                                #endif

                                // used as output loop counters
                                if((output_idx_dim3==weight_dim3/VEC_SIZE-1) && (output_idx_dim2==weight_dim2-1) && (output_idx_dim1==weight_dim1-1)){
                                    output_idx_dim3 = 0;
                                    gp_item_idx_x++;
                                }
                                else if((output_idx_dim2==weight_dim2-1)&& (output_idx_dim1==weight_dim1-1))
                                    output_idx_dim3++;

                                if((output_idx_dim2==weight_dim2-1) && (output_idx_dim1==weight_dim1-1))
                                    output_idx_dim2 = 0;
                                else if(output_idx_dim1==weight_dim1-1)
                                    output_idx_dim2++;

                                if(output_idx_dim1==weight_dim1-1)
                                    output_idx_dim1 = 0;
                                else
                                    output_idx_dim1++;

                            }

                    }

				//		}// end of win_itm_z
				//	}// end of win_itm_y
				//}// end of win_itm_x

                // used as virtual group loop counters for winbuf loading operations
                if((out_idx_z_winbuf==weight_dim4_div_lane-1) && (gp_num_y_winbuf==group_num_y-1) && (gp_num_x_winbuf==group_num_x-1))
                    out_idx_z_winbuf = 0;
                else if((gp_num_y_winbuf==group_num_y-1) && (gp_num_x_winbuf==group_num_x-1))
                    out_idx_z_winbuf++;

                if((gp_num_y_winbuf==group_num_y-1) && (gp_num_x_winbuf==group_num_x-1))
                    gp_num_y_winbuf = 0;
                else if(gp_num_x_winbuf==group_num_x-1)
                    gp_num_y_winbuf++;

                if(gp_num_x_winbuf==group_num_x-1)
                    gp_num_x_winbuf = 0;
                else
                    gp_num_x_winbuf++;

                // used as virtual group loop counters
                if((out_idx_z==weight_dim4_div_lane-1) && (gp_num_y==group_num_y-1) && (gp_num_x==group_num_x-1))
                    out_idx_z = 0;
                else if((gp_num_y==group_num_y-1) && (gp_num_x==group_num_x-1))
                    out_idx_z++;

                if((gp_num_y==group_num_y-1) && (gp_num_x==group_num_x-1))
                    gp_num_y = 0;
                else if(gp_num_x==group_num_x-1)
                    gp_num_y++;

                if(gp_num_x==group_num_x-1)
                    gp_num_x = 0;
                else
                    gp_num_x++;


	//			}// end of gp_num_x
	//		}// end of gp_num_y
	//}// end of out_idx_z
    }

    //printf("Kernel 0 lanched !!!\n");
}


__kernel
__attribute__((reqd_work_group_size(1,1,1)))
//__attribute__((xcl_dataflow))
void coreConv(
    // Params Ports
    uint  output_num,
    uint  conv_loop_cnt,
    uint  contol, //[0]-> relu  [1]->bypass pooling,for ResNet [0]->bn.[1]->wr(fc)
    char  frac_w,
    char  frac_din,
    char  frac_dout
)
{
    channel_vec mac_data;
    channel_vec mac_weight;
    channel_scal bias_ch_out;
    channel_scal conv_ch_in;
    DPTYPE  bias[LANE_NUM];
    MACTYPE conv_out[LANE_NUM];
    MACTYPE lane_accum[LANE_NUM];
    MACTYPE accum_piped[LANE_NUM][PIPE_DEPTH] __attribute__((xcl_array_partition(complete,1))) ;
    MACTYPE conv_sign_exten[LANE_NUM];
    MACTYPE conv_with_rnd_bit[LANE_NUM];
    MACTYPE conv_sum_bias[LANE_NUM];
    DPTYPE  conv_final[LANE_NUM];

    // each iteration generates one output
loop1:
    for(unsigned int k=0; k<output_num; k++){

        bias_ch_read_pipe_block(bias_ch_out);

		__attribute__((opencl_unroll_hint))
		for(unsigned char ll=0; ll<LANE_NUM; ll++){

			conv_out[ll] = CZERO;
			bias[ll] = bias_ch_out.lane[ll]; // pass to reg, avoid compile error

			// initialize the deep pipelined registers which store PIPE_DEPTH copys of partial results
			__attribute__((opencl_unroll_hint))
			for(unsigned int p=0; p<PIPE_DEPTH; p++){
				accum_piped[ll][p] = MASK_ACCUM & CZERO;
			}
		}

loop2:
        for(int j=0; j<conv_loop_cnt; j++){

            // load data and weights for each lane
            data_read_pipe_block(mac_data);
            weight_read_pipe_block(mac_weight);

			// add results from all lanes
			// accumulate with the last copy
            __attribute__((opencl_unroll_hint))
            for(unsigned char ll=0; ll<LANE_NUM; ll++){

                lane_accum[ll] = (MASK_ACCUM & accum_piped[ll][PIPE_DEPTH-1]) + (MASK_MULT & mac(mac_data.lane[ll], mac_weight.lane[ll]));

                // Shift the pipelined registers backwards
                __attribute__((opencl_unroll_hint))
                for(unsigned int p=PIPE_DEPTH-1; p>0; p-- ) {
                    accum_piped[ll][p] = MASK_ACCUM & accum_piped[ll][p-1];
                }

                // update the first copy
                accum_piped[ll][0] = MASK_ACCUM & lane_accum[ll];

                #ifdef DEBUG_CONV
                //if(ll==0 && k==0){
                //	printf("dot_cnt=%d data=%f weight=%f (loop=%d, lane= %d, vec=0)\n", k, (float)mac_data.lane[ll].data[0], (float)mac_weight.lane[ll].data[0], j, ll);
                //}
                #endif
            }
        }// end of conv loop

        __attribute__((opencl_unroll_hint))
        for(unsigned char ll=0; ll<LANE_NUM; ll++){

            // accumulate all the partial results
            __attribute__((opencl_unroll_hint))
            for(unsigned i=0; i<PIPE_DEPTH; i++){
                conv_out[ll] += accum_piped[ll][i];
            }

			// round and truncate the results to the output precision
			// note: ((frac_w+frac_din)-frac_dout)) should be checked by host to be a positive number
            if(conv_out[ll]>=0)
                conv_sign_exten[ll] = 0x00;
            else
                conv_sign_exten[ll] = ~(0xFFFFFFFF>>(frac_w+frac_din-frac_dout-1)); // ">>" is logic shift, then perform sign extension manually

			 // First, perform sign extension and the 1st-step rounding before sum with bias
            conv_with_rnd_bit[ll] = (conv_sign_exten[ll] | (conv_out[ll]>>(frac_w+frac_din-frac_dout-1))) + 0x01;

			// Second, deal with Overflow and Underflow cases and the 2nd rounding after sum with bias
            if(conv_with_rnd_bit[ll]>=256)
                conv_sum_bias[ll] = MASK9B & 0xFF; //=255
            else if(conv_with_rnd_bit[ll]<-256)
                conv_sum_bias[ll] = MASK9B & 0x100; //=-256
            else
			    // clear 1st-step rounding bit by using MASK9B
				// then sum with bias and perform 2nd-step rounding
				// note: (frac_w-frac_dout-1) should be checked by host to be a positive number
                conv_sum_bias[ll] = (MASK9B & conv_with_rnd_bit[ll])+(bias[ll]>>(frac_w-frac_dout-1))+0x01;

            // final truncation
            conv_final[ll] = MASK8B & (conv_sum_bias[ll]>>0x01);  // remove the last rounding bit

#ifdef RESNET
			conv_ch_in.lane[ll]= conv_final[ll];
		}
		//BatchNorm
		if(contol==0)
			conv_ch_write_pipe_block(conv_ch_in);
		else//for fc layer no bn,Write
			bypass_ch_write_pipe_block(conv_ch_in);
#else

            // Relu operation
            if((contol&0x01)==0x01){
                if((conv_final[ll]&MASKSIGN)==MASKSIGN) // MSB is sign bit
                    conv_ch_in.lane[ll] = 0;
                else
                    conv_ch_in.lane[ll] = conv_final[ll];
            }
            else
                conv_ch_in.lane[ll] = conv_final[ll];
                
            #ifdef DEBUG_CONV
            if(ll==0 && k==0)
                printf("dot_cnt=%d sum=%f rnd=%f sum_bias=%f final=%f (bias=%f)\n\n", k, (float)conv_out[ll], (float)conv_with_rnd_bit[ll], (float)conv_sum_bias[ll], (float)conv_final[ll], (float)bias[ll]);
            #endif

        }

        conv_ch_write_pipe_block(conv_ch_in);
#endif
    }// end of output loop
    //printf("Kernel coreConv lanched !!!\n");
}


__kernel
__attribute__((reqd_work_group_size(1,1,1)))
//__attribute__((xcl_dataflow))
void maxPool(
		// Params Ports
		uchar    conv_x,
		ushort   conv_xy,
		uchar    pool_dim1,
		ushort   pool_dim3,
		ushort   pool_dim1x2,
		uchar    pool_size,
		uchar    pool_stride,
		uchar    padd_offset,
		ushort   pool_times, //pool_group*pool_y
		ushort   pool_group, //the number of pooling z dimension vectorized packet
		ushort   pool_y_bound, //pooling bound per pool_y(item_loop_bound*(pool_win_num_x+1))
		ushort   item_loop_bound, // maximum of load_data_bound and write_back_bound
		ushort   load_data_bound, // pooling window buffer load data bound
		ushort   write_back_bound,// pooling window buffer write back result to global memory bound
		uchar    pool_win_num_x, //the number of pool window buffer
		uchar    win_size_x, // pool window buffer size of x dimension
		__global volatile channel_scal * restrict bottom,
		__global DPTYPE * restrict top
		)
{
    bool  pool_sync=0; // Receive channel synchronization signal
	uint  base_addr; // basic address of global memory
	uchar flag; // ping-pong buffer flag

	// the counter of pooling hierarchy
	ushort  pool_group_cnt; // pooling z dimension vectorized packet counter
	uchar   pool_y_cnt; // pooling y dimension counter
	ushort  item_loop_cnt; // the counter of item_loop_bound
	ushort  pool_win_cnt; // the counter of pool_win_num_x(ping-pong +1)
	// the counter of pool window buffer
	uchar   win_item_x; // x dimension
	uchar   win_item_y; // y dimension
	uchar   win_item_s; // pool stride in pool window buffer
	uchar   win_item_cnt; // for win_item_s
	// the counter of write back
	uchar   gp_final_cnt; // pooling result counter in window buffer
	uchar   lane_cnt;
	ushort  global_z;
	ushort  global_index_z_group;
	uchar   global_index_z_item;
	// the register of pooling
	DPTYPE  shift_reg[LANE_NUM][POOL_MAX_SIZE]; // cache from global memory
	DPTYPE  temp_reg0[LANE_NUM];
	DPTYPE  temp_reg1[LANE_NUM];
	DPTYPE  temp_reg2[LANE_NUM];
	DPTYPE  temp_reg[LANE_NUM];
	DPTYPE  temp_max[LANE_NUM];

	DPTYPE  row_reg0[LANE_NUM][POOL_GP_SIZE_X]; // pooling reslut in the first line
	DPTYPE  row_reg1[LANE_NUM][POOL_GP_SIZE_X]; // pooling reslut in the max(second line , first line)
	DPTYPE  pool_final[2][POOL_GP_SIZE_X][LANE_NUM]; // final pooling reslut

	// init hierarchy counters
	pool_y_cnt = 0;
	pool_group_cnt = 0;
	//#pragma ivdep array(pool_final)

    // pool_sync_ch_read_pipe_block(pool_sync);
	for(ushort i = 0; i < pool_times; i++){
		pool_sync_ch_read_pipe_block(pool_sync);
        // barrier((CLK_GLOBAL_MEM_FENCE);

		// init counters
		pool_win_cnt = 0;
		item_loop_cnt = 0;
		win_item_x = 0;
		win_item_y = 0;
		win_item_s = 0;
		win_item_cnt = 0;
		gp_final_cnt = 0;
		lane_cnt = 0;

		//#pragma ivdep array(pool_final)
		for(ushort k=0; k<pool_y_bound; k++){
			flag = pool_win_cnt & 0x01;
			base_addr = pool_group_cnt*conv_xy + pool_stride*conv_x*pool_y_cnt + pool_stride*pool_win_cnt*POOL_GP_SIZE_X;

			// load data from global memory to shift registers and pool (0--pool_win_num_x-1)
			if((pool_win_cnt < pool_win_num_x)&&(item_loop_cnt < load_data_bound)){

				if(win_item_x > pool_size-1){
					win_item_cnt++;
				}
				__attribute__((opencl_unroll_hint))
				for(uchar ll=0; ll<LANE_NUM; ll++){
					if( (pool_win_cnt*POOL_GP_SIZE_X*pool_stride+win_item_x) < conv_x){
						// load global memory to shift register
						shift_reg[ll][0] = bottom[base_addr+win_item_y*conv_x+win_item_x].lane[ll];

						// fetch the data from shift register to pool
						if((win_item_x == pool_size-1) || (win_item_cnt == pool_stride)){
							temp_reg0[ll] = shift_reg[ll][0];
							temp_reg1[ll] = shift_reg[ll][1];
							temp_reg2[ll] = shift_reg[ll][2];
						}

						else{
							temp_reg0[ll] = CZERO;
							temp_reg1[ll] = CZERO;
							temp_reg2[ll] = CZERO;
						}
						// pooling for pool size equal 3
						if(pool_size == 3){
							temp_reg[ll] = pool_max(temp_reg0[ll],temp_reg1[ll]);
							temp_max[ll] = pool_max(temp_reg2[ll],temp_reg[ll]);
							if(win_item_y == 0){
								row_reg0[ll][win_item_s] = temp_max[ll];
							}
							else if(win_item_y == 1){
								row_reg1[ll][win_item_s] = pool_max(temp_max[ll],row_reg0[ll][win_item_s]);
							}
							else{
								pool_final[flag][win_item_s][ll] = pool_max(temp_max[ll],row_reg1[ll][win_item_s]);
							}
						}
						// pooling for pool size equal 2
						else{
							temp_max[ll] = pool_max(temp_reg1[ll],temp_reg0[ll]);
							if(win_item_y == 0){
								row_reg0[ll][win_item_s] = temp_max[ll];
							}
							else{
								pool_final[flag][win_item_s][ll] = pool_max(temp_max[ll],row_reg0[ll][win_item_s]);
							}
						}

						// shift register
						__attribute__((opencl_unroll_hint))
						for(uchar p=POOL_MAX_SIZE-1; p>0; p--){
							shift_reg[ll][p] = shift_reg[ll][p-1];
						}
					}
				}


				if((win_item_x == pool_size-1)||(win_item_cnt == pool_stride)){
					win_item_s++;
				}

				if(win_item_cnt == pool_stride){
					win_item_cnt = 0;
				}

				if((win_item_y == pool_size-1) && (win_item_x == win_size_x-1))
					win_item_y = 0;
				else if(win_item_x == win_size_x-1)
					win_item_y++;
				if(win_item_x == win_size_x-1)
					win_item_x = 0;
				else
					win_item_x++;

				if(win_item_x == 0)
					win_item_s = 0;

			}

			// write back result to global memoey
			// perform vectorization in dim3 (global_z) by combining multiple DPTYPE data into lane_data type
			if((pool_win_cnt > 0) && (item_loop_cnt < write_back_bound)){
				if(((pool_win_cnt-1)*POOL_GP_SIZE_X+gp_final_cnt) < pool_dim1){
					global_z = pool_group_cnt*LANE_NUM+lane_cnt;
					global_index_z_group = (global_z-padd_offset) / VEC_SIZE;
					global_index_z_item =  (global_z-padd_offset) % VEC_SIZE;
					if((global_z-padd_offset)<pool_dim3 && global_z>=padd_offset){
						top[global_index_z_group*pool_dim1x2*VEC_SIZE+pool_y_cnt*pool_dim1*VEC_SIZE+((pool_win_cnt-1)*POOL_GP_SIZE_X+gp_final_cnt)*VEC_SIZE+global_index_z_item] = pool_final[!flag][gp_final_cnt][lane_cnt];
					}
				}

				if((gp_final_cnt == POOL_GP_SIZE_X-1) && (lane_cnt == LANE_NUM-1))
					gp_final_cnt = 0;
				else if(lane_cnt == LANE_NUM-1)
					gp_final_cnt++;
				if(lane_cnt == LANE_NUM-1)
					lane_cnt = 0;
				else
					lane_cnt++;
			}

			if((pool_win_cnt == pool_win_num_x) && (item_loop_cnt == item_loop_bound-1))
				pool_win_cnt = 0;
			else if(item_loop_cnt == item_loop_bound-1)
				pool_win_cnt++;
			if(item_loop_cnt == item_loop_bound-1)
				item_loop_cnt = 0;
			else
				item_loop_cnt++;
		}

		if((pool_group_cnt == pool_group-1) && (pool_y_cnt == pool_dim1-1))
			pool_group_cnt = 0;
		else if(pool_y_cnt == pool_dim1-1)
			pool_group_cnt++;
		if(pool_y_cnt == pool_dim1-1)
			pool_y_cnt = 0;
		else
			pool_y_cnt++;
	}
}

// Store Data to Global Memory
__kernel
__attribute__((reqd_work_group_size(1,1,LANE_NUM)))
void memWrite(
				// Params Ports
				uchar  out_dim1,
				uchar  out_dim2,
				ushort out_dim3,
				ushort out_dim1xbatch, // out_dim1 x sqrt(batch_size)
				uint   out_dim1x2xbatch, // out_dim1 x out_dim2 x batch_size
				uchar  batch_indx_dim1,
				uchar  batch_indx_dim2,
#ifdef RESNET
				uchar  bypass,
				uchar  pool_pad,	  //RESNET need pad,set to 1,other CNN set 0
#endif
				uchar  padd_offset,
				uchar  pool_on,
				uchar  pool_size,
				uchar  pool_stride,
				// Data Ports
				__global DPTYPE *restrict top
				)
{
	uchar  global_x = get_global_id(0); // max value 256
	uchar  global_y = get_global_id(1); // max value 256
	ushort global_z = get_global_id(2); // max value 4096
	uchar  local_x 	= get_local_id(0); // max value 256
	uchar  local_y 	= get_local_id(1); // max value 256
	uchar  local_z 	= get_local_id(2); // max value 256
	ushort group_z  = get_group_id(2);

	uchar  index_z_item; // max value 256
	ushort index_z_group;// max value 4096
	uint   top_addr;
	bool pool_on_signal=1;
    channel_scal output __attribute__((xcl_data_pack(output)));
	__local DPTYPE buffer[LANE_NUM];

	// use the first local work-item to read the vectorized output data from channel
	if(local_z==0){
#ifdef RESNET
    if(bypass==0){//bypass==0,bn
      // for ResNet padding
      if((pool_on == 1) && ((global_y >= out_dim2-pool_pad) || ((global_x >= out_dim1-pool_pad)))){
            __attribute__((opencl_unroll_hint))
    		for(uchar ll=0; ll<LANE_NUM; ll++){
    			output.lane[ll]=CZERO;
    		}
      }
      else{
        pool_ch_read_pipe_block(output);
      }
    }
    else // bypass == 1 bypass_bn_ch
      bypass_ch_read_pipe_block(output);

#else
        conv_ch_read_pipe_block(output);
#endif

		// store the vectorized output into local buffer
		__attribute__((opencl_unroll_hint))
		for(uchar ll=0; ll<LANE_NUM; ll++){
			buffer[ll]=output.lane[ll];
		}
	}

	barrier(CLK_LOCAL_MEM_FENCE);

	// fetch data from local buffer and write back to DDR
	// perform vectorization in dim3 (global_z) by combining multiple DPTYPE data into lane_data type

	if(pool_on == 1){
		top_addr = group_z*out_dim1x2xbatch*LANE_NUM +(global_y+batch_indx_dim2*out_dim2)*out_dim1xbatch*LANE_NUM + (global_x+batch_indx_dim1*out_dim1)*LANE_NUM + local_z;
	}
	else{
		index_z_group = (global_z-padd_offset)/VEC_SIZE;
		index_z_item  = (global_z-padd_offset)%VEC_SIZE;
		top_addr = index_z_group*out_dim1x2xbatch*VEC_SIZE + (global_y+batch_indx_dim2*out_dim2)*out_dim1xbatch*VEC_SIZE + (global_x+batch_indx_dim1*out_dim1)*VEC_SIZE + index_z_item;
	}

	// output dim3 in current layer may be larger than next layer (the value is changed to a value of multiples of LANE_NUM to saturated the wide pipeline input)
	// therefore, only write back the valid values without padding zeros
	if((global_z-padd_offset)<out_dim3 && (global_z>=padd_offset)){
		// 1. addressing expression with out batch processing is
		// top[index_z_group*dim1*dim2*VEC_SIZE + global_y*dim1*VEC_SIZE + global_x*VEC_SIZE + index_z_item]=buffer[local_z];
		// 2. addressing expression with batch processing (batch_size_in_dim = sqrt(batch_size)) is
		// top[(index_z_group*out_dim2*out_dim1*batch_size_in_dim*batch_size_in_dim*VEC_SIZE + (global_y+batch_indx_dim2*out_dim2)*batch_size_in_dim*out_dim1*VEC_SIZE + (global_x+batch_indx_dim1*out_dim1)*VEC_SIZE + index_z_item] = buffer[local_z];
		// 3. simplified addressing with reduced cost of multipliers
		//printf("b=%d\n",index_z_group*out_dim1x2xbatch*VEC_SIZE + (global_y+batch_indx_dim2*out_dim2)*out_dim1xbatch*VEC_SIZE + (global_x+batch_indx_dim1*out_dim1)*VEC_SIZE + index_z_item);

		top[top_addr] = buffer[local_z];
        // #define  DEBUG_MEMWR
		#ifdef DEBUG_MEMWR
		//if((global_z-padd_offset) == 0){
			//for(unsigned char ll=0; ll<LANE_NUM; ll++){
			printf("MemWr results= %f (x=%d, y=%d, z=%d, ll=%d)\n", (float)output.lane[0], global_x, global_y, global_z, 0);
			//}
		//	}
		#endif

	}

    barrier(CLK_LOCAL_MEM_FENCE);

	if(pool_on == 1){
        // ushort global_size_x = get_global_size(0);
        // ushort global_size_y = get_global_size(1);
        // ushort global_size_z = get_global_size(2);

        // if((global_x==global_size_x-1)&&(global_y==global_size_y-1)&&(global_z==global_size_z-1)){
        //     pool_sync_ch_write_pipe_block(pool_on_signal);
        // }
		if((global_x==out_dim1-1)&&(global_y > 0)&&((global_y-pool_size+1)%2 == 0)&&(local_z ==LANE_NUM-1)){
            pool_sync_ch_write_pipe_block(pool_on_signal);
		}
	}

}
