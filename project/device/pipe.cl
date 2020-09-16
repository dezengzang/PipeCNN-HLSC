#ifndef _PIPE_H
#define _PIPE_H

pipe int16 data_ch __attribute__((xcl_reqd_pipe_depth(32)));
pipe int16 weight_ch __attribute__((xcl_reqd_pipe_depth(32)));
#define data_write_pipe_block(input_data)  {int16 temp_data = (int16)(0); char* temp_char_data = &temp_data;\
                                           temp_char_data[0] = input_data.lane[0].data[0]; \
                                           temp_char_data[1] = input_data.lane[0].data[1]; \
                                           temp_char_data[2] = input_data.lane[0].data[2]; \
                                           temp_char_data[3] = input_data.lane[0].data[3]; \
                                           temp_char_data[4] = input_data.lane[1].data[0]; \
                                           temp_char_data[5] = input_data.lane[1].data[1]; \
                                           temp_char_data[6] = input_data.lane[1].data[2]; \
                                           temp_char_data[7] = input_data.lane[1].data[3]; \
                                           temp_char_data[8] = input_data.lane[2].data[0]; \
                                           temp_char_data[9] = input_data.lane[2].data[1]; \
                                           temp_char_data[10] = input_data.lane[2].data[2]; \
                                           temp_char_data[11] = input_data.lane[2].data[3]; \
                                           temp_char_data[12] = input_data.lane[3].data[0]; \
                                           temp_char_data[13] = input_data.lane[3].data[1]; \
                                           temp_char_data[14] = input_data.lane[3].data[2]; \
                                           temp_char_data[15] = input_data.lane[3].data[3]; \
                                           temp_char_data[16] = input_data.lane[4].data[0]; \
                                           temp_char_data[17] = input_data.lane[4].data[1]; \
                                           temp_char_data[18] = input_data.lane[4].data[2]; \
                                           temp_char_data[19] = input_data.lane[4].data[3]; \
                                           temp_char_data[20] = input_data.lane[5].data[0]; \
                                           temp_char_data[21] = input_data.lane[5].data[1]; \
                                           temp_char_data[22] = input_data.lane[5].data[2]; \
                                           temp_char_data[23] = input_data.lane[5].data[3]; \
                                           temp_char_data[24] = input_data.lane[6].data[0]; \
                                           temp_char_data[25] = input_data.lane[6].data[1]; \
                                           temp_char_data[26] = input_data.lane[6].data[2]; \
                                           temp_char_data[27] = input_data.lane[6].data[3]; \
                                           temp_char_data[28] = input_data.lane[7].data[0]; \
                                           temp_char_data[29] = input_data.lane[7].data[1]; \
                                           temp_char_data[30] = input_data.lane[7].data[2]; \
                                           temp_char_data[31] = input_data.lane[7].data[3]; \
                                           temp_char_data[32] = input_data.lane[8].data[0]; \
                                           temp_char_data[33] = input_data.lane[8].data[1]; \
                                           temp_char_data[34] = input_data.lane[8].data[2]; \
                                           temp_char_data[35] = input_data.lane[8].data[3]; \
                                           temp_char_data[36] = input_data.lane[9].data[0]; \
                                           temp_char_data[37] = input_data.lane[9].data[1]; \
                                           temp_char_data[38] = input_data.lane[9].data[2]; \
                                           temp_char_data[39] = input_data.lane[9].data[3]; \
                                           temp_char_data[40] = input_data.lane[10].data[0]; \
                                           temp_char_data[41] = input_data.lane[10].data[1]; \
                                           temp_char_data[42] = input_data.lane[10].data[2]; \
                                           temp_char_data[43] = input_data.lane[10].data[3]; \
                                           temp_char_data[44] = input_data.lane[11].data[0]; \
                                           temp_char_data[45] = input_data.lane[11].data[1]; \
                                           temp_char_data[46] = input_data.lane[11].data[2]; \
                                           temp_char_data[47] = input_data.lane[11].data[3]; \
                                           temp_char_data[48] = input_data.lane[12].data[0]; \
                                           temp_char_data[49] = input_data.lane[12].data[1]; \
                                           temp_char_data[50] = input_data.lane[12].data[2]; \
                                           temp_char_data[51] = input_data.lane[12].data[3]; \
                                           temp_char_data[52] = input_data.lane[13].data[0]; \
                                           temp_char_data[53] = input_data.lane[13].data[1]; \
                                           temp_char_data[54] = input_data.lane[13].data[2]; \
                                           temp_char_data[55] = input_data.lane[13].data[3]; \
                                           temp_char_data[56] = input_data.lane[14].data[0]; \
                                           temp_char_data[57] = input_data.lane[14].data[1]; \
                                           temp_char_data[58] = input_data.lane[14].data[2]; \
                                           temp_char_data[59] = input_data.lane[14].data[3]; \
                                           temp_char_data[60] = input_data.lane[15].data[0]; \
                                           temp_char_data[61] = input_data.lane[15].data[1]; \
                                           temp_char_data[62] = input_data.lane[15].data[2]; \
                                           temp_char_data[63] = input_data.lane[15].data[3]; \
                                           write_pipe_block(data_ch, &temp_data);}

#define data_read_pipe_block(input_data)  {int16 temp_data = (int16)(0); char* temp_char_data = &temp_data;\
                                           read_pipe_block(data_ch, &temp_data);\
                                           input_data.lane[0].data[0] = temp_char_data[0]; \
                                           input_data.lane[0].data[1] = temp_char_data[1]; \
                                           input_data.lane[0].data[2] = temp_char_data[2]; \
                                           input_data.lane[0].data[3] = temp_char_data[3]; \
                                           input_data.lane[1].data[0] = temp_char_data[4]; \
                                           input_data.lane[1].data[1] = temp_char_data[5]; \
                                           input_data.lane[1].data[2] = temp_char_data[6]; \
                                           input_data.lane[1].data[3] = temp_char_data[7]; \
                                           input_data.lane[2].data[0] = temp_char_data[8]; \
                                           input_data.lane[2].data[1] = temp_char_data[9]; \
                                           input_data.lane[2].data[2] = temp_char_data[10]; \
                                           input_data.lane[2].data[3] = temp_char_data[11]; \
                                           input_data.lane[3].data[0] = temp_char_data[12]; \
                                           input_data.lane[3].data[1] = temp_char_data[13]; \
                                           input_data.lane[3].data[2] = temp_char_data[14]; \
                                           input_data.lane[3].data[3] = temp_char_data[15]; \
                                           input_data.lane[4].data[0] = temp_char_data[16]; \
                                           input_data.lane[4].data[1] = temp_char_data[17]; \
                                           input_data.lane[4].data[2] = temp_char_data[18]; \
                                           input_data.lane[4].data[3] = temp_char_data[19]; \
                                           input_data.lane[5].data[0] = temp_char_data[20]; \
                                           input_data.lane[5].data[1] = temp_char_data[21]; \
                                           input_data.lane[5].data[2] = temp_char_data[22]; \
                                           input_data.lane[5].data[3] = temp_char_data[23]; \
                                           input_data.lane[6].data[0] = temp_char_data[24]; \
                                           input_data.lane[6].data[1] = temp_char_data[25]; \
                                           input_data.lane[6].data[2] = temp_char_data[26]; \
                                           input_data.lane[6].data[3] = temp_char_data[27]; \
                                           input_data.lane[7].data[0] = temp_char_data[28]; \
                                           input_data.lane[7].data[1] = temp_char_data[29]; \
                                           input_data.lane[7].data[2] = temp_char_data[30]; \
                                           input_data.lane[7].data[3] = temp_char_data[31]; \
                                           input_data.lane[8].data[0] = temp_char_data[32]; \
                                           input_data.lane[8].data[1] = temp_char_data[33]; \
                                           input_data.lane[8].data[2] = temp_char_data[34]; \
                                           input_data.lane[8].data[3] = temp_char_data[35]; \
                                           input_data.lane[9].data[0] = temp_char_data[36]; \
                                           input_data.lane[9].data[1] = temp_char_data[37]; \
                                           input_data.lane[9].data[2] = temp_char_data[38]; \
                                           input_data.lane[9].data[3] = temp_char_data[39]; \
                                           input_data.lane[10].data[0] = temp_char_data[40]; \
                                           input_data.lane[10].data[1] = temp_char_data[41]; \
                                           input_data.lane[10].data[2] = temp_char_data[42]; \
                                           input_data.lane[10].data[3] = temp_char_data[43]; \
                                           input_data.lane[11].data[0] = temp_char_data[44]; \
                                           input_data.lane[11].data[1] = temp_char_data[45]; \
                                           input_data.lane[11].data[2] = temp_char_data[46]; \
                                           input_data.lane[11].data[3] = temp_char_data[47]; \
                                           input_data.lane[12].data[0] = temp_char_data[48]; \
                                           input_data.lane[12].data[1] = temp_char_data[49]; \
                                           input_data.lane[12].data[2] = temp_char_data[50]; \
                                           input_data.lane[12].data[3] = temp_char_data[51]; \
                                           input_data.lane[13].data[0] = temp_char_data[52]; \
                                           input_data.lane[13].data[1] = temp_char_data[53]; \
                                           input_data.lane[13].data[2] = temp_char_data[54]; \
                                           input_data.lane[13].data[3] = temp_char_data[55]; \
                                           input_data.lane[14].data[0] = temp_char_data[56]; \
                                           input_data.lane[14].data[1] = temp_char_data[57]; \
                                           input_data.lane[14].data[2] = temp_char_data[58]; \
                                           input_data.lane[14].data[3] = temp_char_data[59]; \
                                           input_data.lane[15].data[0] = temp_char_data[60]; \
                                           input_data.lane[15].data[1] = temp_char_data[61]; \
                                           input_data.lane[15].data[2] = temp_char_data[62]; \
                                           input_data.lane[15].data[3] = temp_char_data[63];}

#define weight_write_pipe_block(input_data)  {int16 temp_weight = (int16)(0); char* temp_char_weight = &temp_weight;\
                                           temp_char_weight[0] = input_data.lane[0].data[0]; \
                                           temp_char_weight[1] = input_data.lane[0].data[1]; \
                                           temp_char_weight[2] = input_data.lane[0].data[2]; \
                                           temp_char_weight[3] = input_data.lane[0].data[3]; \
                                           temp_char_weight[4] = input_data.lane[1].data[0]; \
                                           temp_char_weight[5] = input_data.lane[1].data[1]; \
                                           temp_char_weight[6] = input_data.lane[1].data[2]; \
                                           temp_char_weight[7] = input_data.lane[1].data[3]; \
                                           temp_char_weight[8] = input_data.lane[2].data[0]; \
                                           temp_char_weight[9] = input_data.lane[2].data[1]; \
                                           temp_char_weight[10] = input_data.lane[2].data[2]; \
                                           temp_char_weight[11] = input_data.lane[2].data[3]; \
                                           temp_char_weight[12] = input_data.lane[3].data[0]; \
                                           temp_char_weight[13] = input_data.lane[3].data[1]; \
                                           temp_char_weight[14] = input_data.lane[3].data[2]; \
                                           temp_char_weight[15] = input_data.lane[3].data[3]; \
                                           temp_char_weight[16] = input_data.lane[4].data[0]; \
                                           temp_char_weight[17] = input_data.lane[4].data[1]; \
                                           temp_char_weight[18] = input_data.lane[4].data[2]; \
                                           temp_char_weight[19] = input_data.lane[4].data[3]; \
                                           temp_char_weight[20] = input_data.lane[5].data[0]; \
                                           temp_char_weight[21] = input_data.lane[5].data[1]; \
                                           temp_char_weight[22] = input_data.lane[5].data[2]; \
                                           temp_char_weight[23] = input_data.lane[5].data[3]; \
                                           temp_char_weight[24] = input_data.lane[6].data[0]; \
                                           temp_char_weight[25] = input_data.lane[6].data[1]; \
                                           temp_char_weight[26] = input_data.lane[6].data[2]; \
                                           temp_char_weight[27] = input_data.lane[6].data[3]; \
                                           temp_char_weight[28] = input_data.lane[7].data[0]; \
                                           temp_char_weight[29] = input_data.lane[7].data[1]; \
                                           temp_char_weight[30] = input_data.lane[7].data[2]; \
                                           temp_char_weight[31] = input_data.lane[7].data[3]; \
                                           temp_char_weight[32] = input_data.lane[8].data[0]; \
                                           temp_char_weight[33] = input_data.lane[8].data[1]; \
                                           temp_char_weight[34] = input_data.lane[8].data[2]; \
                                           temp_char_weight[35] = input_data.lane[8].data[3]; \
                                           temp_char_weight[36] = input_data.lane[9].data[0]; \
                                           temp_char_weight[37] = input_data.lane[9].data[1]; \
                                           temp_char_weight[38] = input_data.lane[9].data[2]; \
                                           temp_char_weight[39] = input_data.lane[9].data[3]; \
                                           temp_char_weight[40] = input_data.lane[10].data[0]; \
                                           temp_char_weight[41] = input_data.lane[10].data[1]; \
                                           temp_char_weight[42] = input_data.lane[10].data[2]; \
                                           temp_char_weight[43] = input_data.lane[10].data[3]; \
                                           temp_char_weight[44] = input_data.lane[11].data[0]; \
                                           temp_char_weight[45] = input_data.lane[11].data[1]; \
                                           temp_char_weight[46] = input_data.lane[11].data[2]; \
                                           temp_char_weight[47] = input_data.lane[11].data[3]; \
                                           temp_char_weight[48] = input_data.lane[12].data[0]; \
                                           temp_char_weight[49] = input_data.lane[12].data[1]; \
                                           temp_char_weight[50] = input_data.lane[12].data[2]; \
                                           temp_char_weight[51] = input_data.lane[12].data[3]; \
                                           temp_char_weight[52] = input_data.lane[13].data[0]; \
                                           temp_char_weight[53] = input_data.lane[13].data[1]; \
                                           temp_char_weight[54] = input_data.lane[13].data[2]; \
                                           temp_char_weight[55] = input_data.lane[13].data[3]; \
                                           temp_char_weight[56] = input_data.lane[14].data[0]; \
                                           temp_char_weight[57] = input_data.lane[14].data[1]; \
                                           temp_char_weight[58] = input_data.lane[14].data[2]; \
                                           temp_char_weight[59] = input_data.lane[14].data[3]; \
                                           temp_char_weight[60] = input_data.lane[15].data[0]; \
                                           temp_char_weight[61] = input_data.lane[15].data[1]; \
                                           temp_char_weight[62] = input_data.lane[15].data[2]; \
                                           temp_char_weight[63] = input_data.lane[15].data[3]; \
                                           write_pipe_block(weight_ch, &temp_weight);}

#define weight_read_pipe_block(input_data)  {int16 temp_weight = (int16)(0); char* temp_char_weight = &temp_weight;\
                                           read_pipe_block(weight_ch, &temp_weight);\
                                           input_data.lane[0].data[0] = temp_char_weight[0]; \
                                           input_data.lane[0].data[1] = temp_char_weight[1]; \
                                           input_data.lane[0].data[2] = temp_char_weight[2]; \
                                           input_data.lane[0].data[3] = temp_char_weight[3]; \
                                           input_data.lane[1].data[0] = temp_char_weight[4]; \
                                           input_data.lane[1].data[1] = temp_char_weight[5]; \
                                           input_data.lane[1].data[2] = temp_char_weight[6]; \
                                           input_data.lane[1].data[3] = temp_char_weight[7]; \
                                           input_data.lane[2].data[0] = temp_char_weight[8]; \
                                           input_data.lane[2].data[1] = temp_char_weight[9]; \
                                           input_data.lane[2].data[2] = temp_char_weight[10]; \
                                           input_data.lane[2].data[3] = temp_char_weight[11]; \
                                           input_data.lane[3].data[0] = temp_char_weight[12]; \
                                           input_data.lane[3].data[1] = temp_char_weight[13]; \
                                           input_data.lane[3].data[2] = temp_char_weight[14]; \
                                           input_data.lane[3].data[3] = temp_char_weight[15]; \
                                           input_data.lane[4].data[0] = temp_char_weight[16]; \
                                           input_data.lane[4].data[1] = temp_char_weight[17]; \
                                           input_data.lane[4].data[2] = temp_char_weight[18]; \
                                           input_data.lane[4].data[3] = temp_char_weight[19]; \
                                           input_data.lane[5].data[0] = temp_char_weight[20]; \
                                           input_data.lane[5].data[1] = temp_char_weight[21]; \
                                           input_data.lane[5].data[2] = temp_char_weight[22]; \
                                           input_data.lane[5].data[3] = temp_char_weight[23]; \
                                           input_data.lane[6].data[0] = temp_char_weight[24]; \
                                           input_data.lane[6].data[1] = temp_char_weight[25]; \
                                           input_data.lane[6].data[2] = temp_char_weight[26]; \
                                           input_data.lane[6].data[3] = temp_char_weight[27]; \
                                           input_data.lane[7].data[0] = temp_char_weight[28]; \
                                           input_data.lane[7].data[1] = temp_char_weight[29]; \
                                           input_data.lane[7].data[2] = temp_char_weight[30]; \
                                           input_data.lane[7].data[3] = temp_char_weight[31]; \
                                           input_data.lane[8].data[0] = temp_char_weight[32]; \
                                           input_data.lane[8].data[1] = temp_char_weight[33]; \
                                           input_data.lane[8].data[2] = temp_char_weight[34]; \
                                           input_data.lane[8].data[3] = temp_char_weight[35]; \
                                           input_data.lane[9].data[0] = temp_char_weight[36]; \
                                           input_data.lane[9].data[1] = temp_char_weight[37]; \
                                           input_data.lane[9].data[2] = temp_char_weight[38]; \
                                           input_data.lane[9].data[3] = temp_char_weight[39]; \
                                           input_data.lane[10].data[0] = temp_char_weight[40]; \
                                           input_data.lane[10].data[1] = temp_char_weight[41]; \
                                           input_data.lane[10].data[2] = temp_char_weight[42]; \
                                           input_data.lane[10].data[3] = temp_char_weight[43]; \
                                           input_data.lane[11].data[0] = temp_char_weight[44]; \
                                           input_data.lane[11].data[1] = temp_char_weight[45]; \
                                           input_data.lane[11].data[2] = temp_char_weight[46]; \
                                           input_data.lane[11].data[3] = temp_char_weight[47]; \
                                           input_data.lane[12].data[0] = temp_char_weight[48]; \
                                           input_data.lane[12].data[1] = temp_char_weight[49]; \
                                           input_data.lane[12].data[2] = temp_char_weight[50]; \
                                           input_data.lane[12].data[3] = temp_char_weight[51]; \
                                           input_data.lane[13].data[0] = temp_char_weight[52]; \
                                           input_data.lane[13].data[1] = temp_char_weight[53]; \
                                           input_data.lane[13].data[2] = temp_char_weight[54]; \
                                           input_data.lane[13].data[3] = temp_char_weight[55]; \
                                           input_data.lane[14].data[0] = temp_char_weight[56]; \
                                           input_data.lane[14].data[1] = temp_char_weight[57]; \
                                           input_data.lane[14].data[2] = temp_char_weight[58]; \
                                           input_data.lane[14].data[3] = temp_char_weight[59]; \
                                           input_data.lane[15].data[0] = temp_char_weight[60]; \
                                           input_data.lane[15].data[1] = temp_char_weight[61]; \
                                           input_data.lane[15].data[2] = temp_char_weight[62]; \
                                           input_data.lane[15].data[3] = temp_char_weight[63];}

pipe int4 bias_ch __attribute__((xcl_reqd_pipe_depth(32)));
pipe int4 conv_ch __attribute__((xcl_reqd_pipe_depth(32)));
pipe int4 batchNorm_ch __attribute__((xcl_reqd_pipe_depth(32)));
pipe int4 bypass_bn_ch __attribute__((xcl_reqd_pipe_depth(32)));
#define bias_ch_write_pipe_block(input_data)  {int4 temp_bias_ch = (int4)(0); char* temp_char_bias_ch = &temp_bias_ch;\
                                           temp_char_bias_ch[0] = input_data.lane[0]; \
                                           temp_char_bias_ch[1] = input_data.lane[1]; \
                                           temp_char_bias_ch[2] = input_data.lane[2]; \
                                           temp_char_bias_ch[3] = input_data.lane[3]; \
                                           temp_char_bias_ch[4] = input_data.lane[4]; \
                                           temp_char_bias_ch[5] = input_data.lane[5]; \
                                           temp_char_bias_ch[6] = input_data.lane[6]; \
                                           temp_char_bias_ch[7] = input_data.lane[7]; \
                                           temp_char_bias_ch[8] = input_data.lane[8]; \
                                           temp_char_bias_ch[9] = input_data.lane[9]; \
                                           temp_char_bias_ch[10] = input_data.lane[10]; \
                                           temp_char_bias_ch[11] = input_data.lane[11]; \
                                           temp_char_bias_ch[12] = input_data.lane[12]; \
                                           temp_char_bias_ch[13] = input_data.lane[13]; \
                                           temp_char_bias_ch[14] = input_data.lane[14]; \
                                           temp_char_bias_ch[15] = input_data.lane[15]; \
                                           write_pipe_block(bias_ch, &temp_bias_ch);}

#define bias_ch_read_pipe_block(input_data)  {int4 temp_bias_ch = (int4)(0); char* temp_char_bias_ch = &temp_bias_ch;\
                                           read_pipe_block(bias_ch, &temp_bias_ch);\
                                           input_data.lane[0] = temp_char_bias_ch[0]; \
                                           input_data.lane[1] = temp_char_bias_ch[1]; \
                                           input_data.lane[2] = temp_char_bias_ch[2]; \
                                           input_data.lane[3] = temp_char_bias_ch[3]; \
                                           input_data.lane[4] = temp_char_bias_ch[4]; \
                                           input_data.lane[5] = temp_char_bias_ch[5]; \
                                           input_data.lane[6] = temp_char_bias_ch[6]; \
                                           input_data.lane[7] = temp_char_bias_ch[7]; \
                                           input_data.lane[8] = temp_char_bias_ch[8]; \
                                           input_data.lane[9] = temp_char_bias_ch[9]; \
                                           input_data.lane[10] = temp_char_bias_ch[10]; \
                                           input_data.lane[11] = temp_char_bias_ch[11]; \
                                           input_data.lane[12] = temp_char_bias_ch[12]; \
                                           input_data.lane[13] = temp_char_bias_ch[13]; \
                                           input_data.lane[14] = temp_char_bias_ch[14]; \
                                           input_data.lane[15] = temp_char_bias_ch[15];}

#define conv_ch_write_pipe_block(input_data)  {int4 temp_conv_ch = (int4)(0); char* temp_char_conv_ch = &temp_conv_ch;\
                                           temp_char_conv_ch[0] = input_data.lane[0]; \
                                           temp_char_conv_ch[1] = input_data.lane[1]; \
                                           temp_char_conv_ch[2] = input_data.lane[2]; \
                                           temp_char_conv_ch[3] = input_data.lane[3]; \
                                           temp_char_conv_ch[4] = input_data.lane[4]; \
                                           temp_char_conv_ch[5] = input_data.lane[5]; \
                                           temp_char_conv_ch[6] = input_data.lane[6]; \
                                           temp_char_conv_ch[7] = input_data.lane[7]; \
                                           temp_char_conv_ch[8] = input_data.lane[8]; \
                                           temp_char_conv_ch[9] = input_data.lane[9]; \
                                           temp_char_conv_ch[10] = input_data.lane[10]; \
                                           temp_char_conv_ch[11] = input_data.lane[11]; \
                                           temp_char_conv_ch[12] = input_data.lane[12]; \
                                           temp_char_conv_ch[13] = input_data.lane[13]; \
                                           temp_char_conv_ch[14] = input_data.lane[14]; \
                                           temp_char_conv_ch[15] = input_data.lane[15]; \
                                           write_pipe_block(conv_ch, &temp_conv_ch);}

#define conv_ch_read_pipe_block(input_data)  {int4 temp_conv_ch = (int4)(0); char* temp_char_conv_ch = &temp_conv_ch;\
                                           read_pipe_block(conv_ch, &temp_conv_ch);\
                                           input_data.lane[0] = temp_char_conv_ch[0]; \
                                           input_data.lane[1] = temp_char_conv_ch[1]; \
                                           input_data.lane[2] = temp_char_conv_ch[2]; \
                                           input_data.lane[3] = temp_char_conv_ch[3]; \
                                           input_data.lane[4] = temp_char_conv_ch[4]; \
                                           input_data.lane[5] = temp_char_conv_ch[5]; \
                                           input_data.lane[6] = temp_char_conv_ch[6]; \
                                           input_data.lane[7] = temp_char_conv_ch[7]; \
                                           input_data.lane[8] = temp_char_conv_ch[8]; \
                                           input_data.lane[9] = temp_char_conv_ch[9]; \
                                           input_data.lane[10] = temp_char_conv_ch[10]; \
                                           input_data.lane[11] = temp_char_conv_ch[11]; \
                                           input_data.lane[12] = temp_char_conv_ch[12]; \
                                           input_data.lane[13] = temp_char_conv_ch[13]; \
                                           input_data.lane[14] = temp_char_conv_ch[14]; \
                                           input_data.lane[15] = temp_char_conv_ch[15];}

#define batchNorm_ch_write_pipe_block(input_data)  {int4 temp_batchNorm_ch = (int4)(0); char* temp_char_batchNorm_ch = &temp_batchNorm_ch;\
                                           temp_char_batchNorm_ch[0] = input_data.lane[0]; \
                                           temp_char_batchNorm_ch[1] = input_data.lane[1]; \
                                           temp_char_batchNorm_ch[2] = input_data.lane[2]; \
                                           temp_char_batchNorm_ch[3] = input_data.lane[3]; \
                                           temp_char_batchNorm_ch[4] = input_data.lane[4]; \
                                           temp_char_batchNorm_ch[5] = input_data.lane[5]; \
                                           temp_char_batchNorm_ch[6] = input_data.lane[6]; \
                                           temp_char_batchNorm_ch[7] = input_data.lane[7]; \
                                           temp_char_batchNorm_ch[8] = input_data.lane[8]; \
                                           temp_char_batchNorm_ch[9] = input_data.lane[9]; \
                                           temp_char_batchNorm_ch[10] = input_data.lane[10]; \
                                           temp_char_batchNorm_ch[11] = input_data.lane[11]; \
                                           temp_char_batchNorm_ch[12] = input_data.lane[12]; \
                                           temp_char_batchNorm_ch[13] = input_data.lane[13]; \
                                           temp_char_batchNorm_ch[14] = input_data.lane[14]; \
                                           temp_char_batchNorm_ch[15] = input_data.lane[15]; \
                                           write_pipe_block(batchNorm_ch, &temp_batchNorm_ch);}

#define batchNorm_ch_read_pipe_block(input_data)  {int4 temp_batchNorm_ch = (int4)(0); char* temp_char_batchNorm_ch = &temp_batchNorm_ch;\
                                           read_pipe_block(batchNorm_ch, &temp_batchNorm_ch);\
                                           input_data.lane[0] = temp_char_batchNorm_ch[0]; \
                                           input_data.lane[1] = temp_char_batchNorm_ch[1]; \
                                           input_data.lane[2] = temp_char_batchNorm_ch[2]; \
                                           input_data.lane[3] = temp_char_batchNorm_ch[3]; \
                                           input_data.lane[4] = temp_char_batchNorm_ch[4]; \
                                           input_data.lane[5] = temp_char_batchNorm_ch[5]; \
                                           input_data.lane[6] = temp_char_batchNorm_ch[6]; \
                                           input_data.lane[7] = temp_char_batchNorm_ch[7]; \
                                           input_data.lane[8] = temp_char_batchNorm_ch[8]; \
                                           input_data.lane[9] = temp_char_batchNorm_ch[9]; \
                                           input_data.lane[10] = temp_char_batchNorm_ch[10]; \
                                           input_data.lane[11] = temp_char_batchNorm_ch[11]; \
                                           input_data.lane[12] = temp_char_batchNorm_ch[12]; \
                                           input_data.lane[13] = temp_char_batchNorm_ch[13]; \
                                           input_data.lane[14] = temp_char_batchNorm_ch[14]; \
                                           input_data.lane[15] = temp_char_batchNorm_ch[15];}

#define bypass_bn_ch_write_pipe_block(input_data)  {int4 temp_bypass_bn_ch = (int4)(0); char* temp_char_bypass_bn_ch = &temp_bypass_bn_ch;\
                                           temp_char_bypass_bn_ch[0] = input_data.lane[0]; \
                                           temp_char_bypass_bn_ch[1] = input_data.lane[1]; \
                                           temp_char_bypass_bn_ch[2] = input_data.lane[2]; \
                                           temp_char_bypass_bn_ch[3] = input_data.lane[3]; \
                                           temp_char_bypass_bn_ch[4] = input_data.lane[4]; \
                                           temp_char_bypass_bn_ch[5] = input_data.lane[5]; \
                                           temp_char_bypass_bn_ch[6] = input_data.lane[6]; \
                                           temp_char_bypass_bn_ch[7] = input_data.lane[7]; \
                                           temp_char_bypass_bn_ch[8] = input_data.lane[8]; \
                                           temp_char_bypass_bn_ch[9] = input_data.lane[9]; \
                                           temp_char_bypass_bn_ch[10] = input_data.lane[10]; \
                                           temp_char_bypass_bn_ch[11] = input_data.lane[11]; \
                                           temp_char_bypass_bn_ch[12] = input_data.lane[12]; \
                                           temp_char_bypass_bn_ch[13] = input_data.lane[13]; \
                                           temp_char_bypass_bn_ch[14] = input_data.lane[14]; \
                                           temp_char_bypass_bn_ch[15] = input_data.lane[15]; \
                                           write_pipe_block(bypass_bn_ch, &temp_bypass_bn_ch);}

#define bypass_bn_ch_read_pipe_block(input_data)  {int4 temp_bypass_bn_ch = (int4)(0); char* temp_char_bypass_bn_ch = &temp_bypass_bn_ch;\
                                           read_pipe_block(bypass_bn_ch, &temp_bypass_bn_ch);\
                                           input_data.lane[0] = temp_char_bypass_bn_ch[0]; \
                                           input_data.lane[1] = temp_char_bypass_bn_ch[1]; \
                                           input_data.lane[2] = temp_char_bypass_bn_ch[2]; \
                                           input_data.lane[3] = temp_char_bypass_bn_ch[3]; \
                                           input_data.lane[4] = temp_char_bypass_bn_ch[4]; \
                                           input_data.lane[5] = temp_char_bypass_bn_ch[5]; \
                                           input_data.lane[6] = temp_char_bypass_bn_ch[6]; \
                                           input_data.lane[7] = temp_char_bypass_bn_ch[7]; \
                                           input_data.lane[8] = temp_char_bypass_bn_ch[8]; \
                                           input_data.lane[9] = temp_char_bypass_bn_ch[9]; \
                                           input_data.lane[10] = temp_char_bypass_bn_ch[10]; \
                                           input_data.lane[11] = temp_char_bypass_bn_ch[11]; \
                                           input_data.lane[12] = temp_char_bypass_bn_ch[12]; \
                                           input_data.lane[13] = temp_char_bypass_bn_ch[13]; \
                                           input_data.lane[14] = temp_char_bypass_bn_ch[14]; \
                                           input_data.lane[15] = temp_char_bypass_bn_ch[15];}

pipe bool pool_sync_ch __attribute__((xcl_reqd_pipe_depth(32)));
#define pool_sync_ch_write_pipe_block(input_data) { bool temp; \
                                                    temp = input_data; \
                                                    write_pipe_block(pool_sync_ch, &temp); }
#define pool_sync_ch_read_pipe_block(input_data)  { bool temp; \
                                                    read_pipe_block (pool_sync_ch, &temp);\
                                                    input_data = temp;}

#endif
