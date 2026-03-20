/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Ultra(TM) in wire load mode
// Version   : K-2015.06-SP2
// Date      : Fri Mar 20 01:44:58 2026
/////////////////////////////////////////////////////////////


module fifo_depth16_async_bw24_0_DW01_inc_J1_0_1 ( A, SUM );
  input [4:0] A;
  output [4:0] SUM;
  wire   n1, n2, n3;

  HA1D0 U2 ( .A(n2), .B(A[3]), .CO(n1), .S(SUM[3]) );
  HA1D0 U3 ( .A(n3), .B(A[2]), .CO(n2), .S(SUM[2]) );
  HA1D0 U4 ( .A(A[0]), .B(A[1]), .CO(n3), .S(SUM[1]) );
  CKXOR2D0 U8 ( .A1(n1), .A2(A[4]), .Z(SUM[4]) );
  INVD0 U9 ( .I(A[0]), .ZN(SUM[0]) );
endmodule


module fifo_depth16_async_bw24_0_DW01_inc_J1_1_1 ( A, SUM );
  input [4:0] A;
  output [4:0] SUM;
  wire   n1, n2, n3;

  HA1D0 U2 ( .A(n2), .B(A[3]), .CO(n1), .S(SUM[3]) );
  HA1D0 U3 ( .A(n3), .B(A[2]), .CO(n2), .S(SUM[2]) );
  HA1D0 U4 ( .A(A[0]), .B(A[1]), .CO(n3), .S(SUM[1]) );
  CKXOR2D0 U8 ( .A1(n1), .A2(A[4]), .Z(SUM[4]) );
  INVD0 U9 ( .I(A[0]), .ZN(SUM[0]) );
endmodule


module fifo_depth16_async_bw24_2 ( rd_clk, wr_clk, rd, wr, reset, in, out, 
        o_full, o_empty );
  input [23:0] in;
  output [23:0] out;
  input rd_clk, wr_clk, rd, wr, reset;
  output o_full, o_empty;
  wire   n1, n576, rd_fire, rd_ptr_gray_sync_wr1_4_, N17, N37, N40, N48, n29,
         n30, n31, n38, n39, n40, net31619, net31624, net31638, net31639,
         net33754, net34680, net34682, net34686, net34688, net34692, net34693,
         net34697, net34698, net34702, net34704, net34713, net34714, net34716,
         net34717, net34718, net34726, net34727, net34822, net34824, net34860,
         net34874, net34873, net34902, net34914, net34940, net35113, net35112,
         net35118, net34709, n20, net34831, net34830, net34723, net34722, n2,
         n3, n4, n5, n6, n7, n8, n9, n10, n11, n12, n13, n14, n15, n16, n17,
         n18, n19, n21, n22, n23, n24, n25, n26, n27, n28, n32, n33, n34, n35,
         n36, n37, n41, n42, n43, n44, n45, n46, n47, n48, n49, n50, n51, n52,
         n53, n54, n55, n56, n57, n58, n59, n60, n61, n62, n63, n64, n65, n66,
         n67, n68, n69, n70, n71, n72, n73, n74, n75, n76, n77, n78, n79, n80,
         n81, n82, n83, n84, n85, n86, n87, n88, n89, n90, n91, n92, n93, n94,
         n95, n96, n97, n98, n99, n100, n101, n102, n103, n104, n105, n106,
         n107, n108, n109, n110, n111, n112, n113, n114, n115, n116, n117,
         n118, n119, n120, n121, n122, n123, n124, n125, n126, n127, n128,
         n129, n130, n131, n132, n133, n134, n135, n136, n137, n138, n139,
         n140, n141, n142, n143, n144, n145, n146, n147, n148, n149, n150,
         n151, n152, n153, n154, n155, n156, n157, n158, n159, n160, n161,
         n162, n163, n164, n165, n166, n167, n168, n169, n170, n171, n172,
         n173, n174, n175, n176, n177, n178, n179, n180, n181, n182, n183,
         n184, n185, n186, n187, n188, n189, n190, n191, n192, n193, n194,
         n195, n196, n197, n198, n199, n200, n201, n202, n203, n204, n205,
         n206, n207, n208, n209, n210, n211, n212, n213, n214, n215, n216,
         n217, n218, n219, n220, n221, n222, n223, n224, n225, n226, n227,
         n228, n229, n230, n231, n232, n233, n234, n235, n236, n237, n238,
         n239, n240, n241, n242, n243, n244, n245, n246, n247, n248, n249,
         n250, n251, n252, n253, n254, n255, n256, n257, n258, n259, n260,
         n261, n262, n263, n264, n265, n266, n267, n268, n269, n270, n271,
         n272, n273, n274, n275, n276, n277, n278, n279, n280, n281, n282,
         n283, n284, n285, n286, n287, n288, n289, n290, n291, n292, n293,
         n294, n295, n296, n297, n298, n299, n300, n301, n302, n303, n304,
         n305, n306, n307, n308, n309, n310, n311, n312, n313, n314, n315,
         n316, n317, n318, n319, n320, n321, n322, n323, n324, n325, n326,
         n327, n328, n329, n330, n331, n332, n333, n334, n335, n336, n337,
         n338, n339, n340, n341, n342, n343, n344, n345, n346, n347, n348,
         n349, n350, n351, n352, n353, n354, n355, n356, n357, n358, n359,
         n360, n361, n362, n363, n364, n365, n366, n367, n368, n369, n370,
         n371, n372, n373, n374, n375, n376, n377, n378, n379, n380, n381,
         n382, n383, n384, n385, n386, n387, n388, n389, n390, n391, n392,
         n393, n394, n395, n396, n397, n398, n399, n400, n401, n402, n403,
         n404, n405, n406, n407, n408, n409, n410, n411, n412, n413, n414,
         n415, n416, n417, n418, n419, n420, n421, n422, n423, n424, n425,
         n426, n427, n428, n429, n430, n431, n432, n433, n434, n435, n436,
         n437, n438, n439, n440, n441, n442, n443, n444, n445, n446, n447,
         n448, n449, n450, n451, n452, n453, n454, n455, n456, n457, n458,
         n459, n460, n461, n462, n463, n464, n465, n466, n467, n468, n469,
         n470, n471, n472, n473, n474, n476, n477, n478, n479, n480, n481,
         n482, n483, n484, n485, n486, n487, n488, n489, n490, n491, n492,
         n493, n494, n495, n496, n497, n498, n499, n500, n501, n502, n503,
         n504, n505, n506, n507, n508, n509, n510, n511, n512, n513, n514,
         n515, n516, n517, n518, n519, n520, n521, n522, n523, n524, n525,
         n526, n527, n528, n529, n530, n531, n532, n533, n534, n535, n536,
         n537, n538, n539, n540, n541, n542, n543, n544, n545, n546, n547,
         n548, n549, n550, n551, n552, n553, n554, n555, n556, n557, n558,
         n559, n560, n561, n562, n563, n564, n565, n566, n567, n568, n569,
         n570, n571, n572, n573, n574, n575;
  wire   [3:0] rd_ptr_bin;
  wire   [2:0] wr_ptr_bin;
  wire   [4:3] wr_ptr_bin_next;
  wire   [3:0] wr_ptr_gray_next;
  wire   [4:0] rd_ptr_gray;
  tri   rd_clk;
  tri   wr_clk;
  tri   rd;
  tri   wr;
  tri   reset;
  tri   [23:0] in;

  fifo_depth16_async_bw24_0_DW01_inc_J1_0_1 add_x_2 ( .A({n60, net31638, 
        net31639, net34874, net34902}), .SUM({wr_ptr_bin_next, wr_ptr_bin}) );
  fifo_depth16_async_bw24_0_DW01_inc_J1_1_1 add_x_1 ( .A({
        rd_ptr_gray_sync_wr1_4_, n469, n467, n465, n463}), .SUM({
        rd_ptr_gray[4], rd_ptr_bin}) );
  NR3D0 U61 ( .A1(n31), .A2(n30), .A3(n29), .ZN(n576) );
  NR3D0 U71 ( .A1(n40), .A2(n39), .A3(n38), .ZN(n1) );
  AO22D0 U87 ( .A1(net34718), .A2(N17), .B1(net34940), .B2(n474), .Z(N48) );
  DFSNQD1 clk1_r_REG0_S1 ( .D(n574), .CP(rd_clk), .SDN(n3), .Q(n473) );
  DFSNQD1 clk1_r_REG1_S1 ( .D(n575), .CP(rd_clk), .SDN(n53), .Q(n472) );
  DFSNQD1 clk1_r_REG2_S1 ( .D(n572), .CP(rd_clk), .SDN(n3), .Q(n471) );
  DFSNQD1 clk1_r_REG3_S1 ( .D(n573), .CP(rd_clk), .SDN(n53), .Q(n470) );
  EDFCNQD4 clk1_r_REG399_S1 ( .D(rd_ptr_bin[1]), .E(rd_fire), .CP(rd_clk), 
        .CDN(n3), .Q(n465) );
  DFCNQD1 clk1_r_REG407_S1 ( .D(n60), .CP(rd_clk), .CDN(n5), .Q(n462) );
  DFCNQD1 clk1_r_REG408_S1 ( .D(n62), .CP(rd_clk), .CDN(n43), .Q(n461) );
  DFCNQD1 clk1_r_REG409_S1 ( .D(n63), .CP(rd_clk), .CDN(n43), .Q(n460) );
  DFCNQD1 clk1_r_REG410_S1 ( .D(n64), .CP(rd_clk), .CDN(n43), .Q(n459) );
  DFCNQD1 clk1_r_REG411_S1 ( .D(n72), .CP(rd_clk), .CDN(n3), .Q(n458) );
  DFCNQD1 clk1_r_REG412_S1 ( .D(n458), .CP(rd_clk), .CDN(n3), .Q(n457) );
  DFCNQD1 clk0_r_REG385_S1 ( .D(rd_ptr_gray[0]), .CP(wr_clk), .CDN(n5), .Q(n71) );
  DFCNQD1 clk0_r_REG386_S1 ( .D(n71), .CP(wr_clk), .CDN(n53), .Q(n70) );
  DFCNQD1 clk0_r_REG387_S1 ( .D(rd_ptr_gray[1]), .CP(wr_clk), .CDN(n53), .Q(
        n69) );
  DFCNQD1 clk0_r_REG388_S1 ( .D(n69), .CP(wr_clk), .CDN(n3), .Q(n68) );
  DFCNQD1 clk0_r_REG389_S1 ( .D(rd_ptr_gray[2]), .CP(wr_clk), .CDN(n43), .Q(
        n67) );
  DFCNQD1 clk0_r_REG390_S1 ( .D(n67), .CP(wr_clk), .CDN(n52), .Q(n66) );
  DFCNQD1 clk0_r_REG391_S1 ( .D(rd_ptr_gray[3]), .CP(wr_clk), .CDN(n3), .Q(n65) );
  DFCNQD1 clk0_r_REG392_S1 ( .D(n65), .CP(wr_clk), .CDN(n5), .Q(net31619) );
  DFCNQD1 clk0_r_REG396_S1 ( .D(rd_ptr_gray_sync_wr1_4_), .CP(wr_clk), .CDN(n5), .Q(n61) );
  DFSND1 clk1_r_REG396_S1 ( .D(n59), .CP(rd_clk), .SDN(n52), .Q(n468), .QN(n49) );
  DFSND1 clk1_r_REG398_S1 ( .D(n58), .CP(rd_clk), .SDN(n52), .Q(n466), .QN(n51) );
  DFSND1 clk1_r_REG400_S1 ( .D(n57), .CP(rd_clk), .SDN(n52), .Q(n464), .QN(n50) );
  EDFCNQD1 clk0_r_REG410_S1 ( .D(wr_ptr_bin[2]), .E(n4), .CP(wr_clk), .CDN(n3), 
        .Q(net31639) );
  EDFCNQD1 clk0_r_REG395_S1 ( .D(wr_ptr_gray_next[3]), .E(n4), .CP(wr_clk), 
        .CDN(n3), .Q(n62) );
  EDFCNQD1 clk0_r_REG394_S1 ( .D(n56), .E(n4), .CP(wr_clk), .CDN(n43), .Q(n63)
         );
  EDFCNQD1 clk0_r_REG384_S1 ( .D(wr_ptr_gray_next[0]), .E(n4), .CP(wr_clk), 
        .CDN(n3), .Q(n72) );
  EDFCNQD4 clk1_r_REG401_S1 ( .D(rd_ptr_bin[0]), .E(rd_fire), .CP(rd_clk), 
        .CDN(n43), .Q(n463) );
  EDFCNQD1 clk0_r_REG0_S1 ( .D(in[23]), .E(n6), .CP(wr_clk), .CDN(n5), .Q(n456) );
  EDFCNQD1 clk0_r_REG2_S1 ( .D(in[23]), .E(n54), .CP(wr_clk), .CDN(n3), .Q(
        n454) );
  EDFCNQD1 clk0_r_REG6_S1 ( .D(in[23]), .E(n23), .CP(wr_clk), .CDN(n3), .Q(
        n450) );
  EDFCNQD1 clk0_r_REG8_S1 ( .D(in[23]), .E(n21), .CP(wr_clk), .CDN(n3), .Q(
        n448) );
  EDFCNQD1 clk0_r_REG10_S1 ( .D(in[23]), .E(n2), .CP(wr_clk), .CDN(n3), .Q(
        n446) );
  EDFCNQD1 clk0_r_REG12_S1 ( .D(in[23]), .E(net34914), .CP(wr_clk), .CDN(n5), 
        .Q(n444) );
  EDFCNQD1 clk0_r_REG14_S1 ( .D(in[23]), .E(net34860), .CP(wr_clk), .CDN(n5), 
        .Q(n442) );
  EDFCNQD1 clk0_r_REG16_S1 ( .D(in[22]), .E(n6), .CP(wr_clk), .CDN(n53), .Q(
        n440) );
  EDFCNQD1 clk0_r_REG18_S1 ( .D(in[22]), .E(n54), .CP(wr_clk), .CDN(n3), .Q(
        n438) );
  EDFCNQD1 clk0_r_REG20_S1 ( .D(in[22]), .E(n17), .CP(wr_clk), .CDN(n3), .Q(
        n436) );
  EDFCNQD1 clk0_r_REG22_S1 ( .D(in[22]), .E(n23), .CP(wr_clk), .CDN(n3), .Q(
        n434) );
  EDFCNQD1 clk0_r_REG24_S1 ( .D(in[22]), .E(n21), .CP(wr_clk), .CDN(n3), .Q(
        n432) );
  EDFCNQD1 clk0_r_REG26_S1 ( .D(in[22]), .E(n2), .CP(wr_clk), .CDN(n3), .Q(
        n430) );
  EDFCNQD1 clk0_r_REG28_S1 ( .D(in[22]), .E(net34914), .CP(wr_clk), .CDN(n3), 
        .Q(n428) );
  EDFCNQD1 clk0_r_REG30_S1 ( .D(in[22]), .E(net34860), .CP(wr_clk), .CDN(n3), 
        .Q(n426) );
  EDFCNQD1 clk0_r_REG32_S1 ( .D(in[21]), .E(n6), .CP(wr_clk), .CDN(n3), .Q(
        n424) );
  EDFCNQD1 clk0_r_REG34_S1 ( .D(in[21]), .E(n54), .CP(wr_clk), .CDN(n43), .Q(
        n422) );
  EDFCNQD1 clk0_r_REG36_S1 ( .D(in[21]), .E(n18), .CP(wr_clk), .CDN(n3), .Q(
        n420) );
  EDFCNQD1 clk0_r_REG38_S1 ( .D(in[21]), .E(n23), .CP(wr_clk), .CDN(n5), .Q(
        n418) );
  EDFCNQD1 clk0_r_REG40_S1 ( .D(in[21]), .E(n21), .CP(wr_clk), .CDN(n3), .Q(
        n416) );
  EDFCNQD1 clk0_r_REG42_S1 ( .D(in[21]), .E(n2), .CP(wr_clk), .CDN(n3), .Q(
        n414) );
  EDFCNQD1 clk0_r_REG44_S1 ( .D(in[21]), .E(net34914), .CP(wr_clk), .CDN(n3), 
        .Q(n412) );
  EDFCNQD1 clk0_r_REG46_S1 ( .D(in[21]), .E(net34860), .CP(wr_clk), .CDN(n3), 
        .Q(n410) );
  EDFCNQD1 clk0_r_REG48_S1 ( .D(in[20]), .E(n6), .CP(wr_clk), .CDN(n3), .Q(
        n408) );
  EDFCNQD1 clk0_r_REG50_S1 ( .D(in[20]), .E(n54), .CP(wr_clk), .CDN(n5), .Q(
        n406) );
  EDFCNQD1 clk0_r_REG52_S1 ( .D(in[20]), .E(n17), .CP(wr_clk), .CDN(n3), .Q(
        n404) );
  EDFCNQD1 clk0_r_REG54_S1 ( .D(in[20]), .E(n23), .CP(wr_clk), .CDN(n5), .Q(
        n402) );
  EDFCNQD1 clk0_r_REG56_S1 ( .D(in[20]), .E(n21), .CP(wr_clk), .CDN(n53), .Q(
        n400) );
  EDFCNQD1 clk0_r_REG58_S1 ( .D(in[20]), .E(n2), .CP(wr_clk), .CDN(n3), .Q(
        n398) );
  EDFCNQD1 clk0_r_REG60_S1 ( .D(in[20]), .E(net34914), .CP(wr_clk), .CDN(n3), 
        .Q(n396) );
  EDFCNQD1 clk0_r_REG62_S1 ( .D(in[20]), .E(net34860), .CP(wr_clk), .CDN(n3), 
        .Q(n394) );
  EDFCNQD1 clk0_r_REG64_S1 ( .D(in[19]), .E(n6), .CP(wr_clk), .CDN(n3), .Q(
        n392) );
  EDFCNQD1 clk0_r_REG66_S1 ( .D(in[19]), .E(n54), .CP(wr_clk), .CDN(n53), .Q(
        n390) );
  EDFCNQD1 clk0_r_REG70_S1 ( .D(in[19]), .E(n23), .CP(wr_clk), .CDN(n53), .Q(
        n386) );
  EDFCNQD1 clk0_r_REG72_S1 ( .D(in[19]), .E(n21), .CP(wr_clk), .CDN(n53), .Q(
        n384) );
  EDFCNQD1 clk0_r_REG74_S1 ( .D(in[19]), .E(n2), .CP(wr_clk), .CDN(n3), .Q(
        n382) );
  EDFCNQD1 clk0_r_REG76_S1 ( .D(in[19]), .E(net34914), .CP(wr_clk), .CDN(n3), 
        .Q(n380) );
  EDFCNQD1 clk0_r_REG78_S1 ( .D(in[19]), .E(net34860), .CP(wr_clk), .CDN(n3), 
        .Q(n378) );
  EDFCNQD1 clk0_r_REG80_S1 ( .D(in[18]), .E(n6), .CP(wr_clk), .CDN(n5), .Q(
        n376) );
  EDFCNQD1 clk0_r_REG82_S1 ( .D(in[18]), .E(n54), .CP(wr_clk), .CDN(n53), .Q(
        n374) );
  EDFCNQD1 clk0_r_REG84_S1 ( .D(in[18]), .E(n18), .CP(wr_clk), .CDN(n3), .Q(
        n372) );
  EDFCNQD1 clk0_r_REG86_S1 ( .D(in[18]), .E(n23), .CP(wr_clk), .CDN(n3), .Q(
        n370) );
  EDFCNQD1 clk0_r_REG88_S1 ( .D(in[18]), .E(n21), .CP(wr_clk), .CDN(n3), .Q(
        n368) );
  EDFCNQD1 clk0_r_REG90_S1 ( .D(in[18]), .E(n2), .CP(wr_clk), .CDN(n3), .Q(
        n366) );
  EDFCNQD1 clk0_r_REG92_S1 ( .D(in[18]), .E(net34914), .CP(wr_clk), .CDN(n53), 
        .Q(n364) );
  EDFCNQD1 clk0_r_REG94_S1 ( .D(in[18]), .E(net34860), .CP(wr_clk), .CDN(n53), 
        .Q(n362) );
  EDFCNQD1 clk0_r_REG96_S1 ( .D(in[17]), .E(n6), .CP(wr_clk), .CDN(n53), .Q(
        n360) );
  EDFCNQD1 clk0_r_REG98_S1 ( .D(in[17]), .E(n54), .CP(wr_clk), .CDN(n3), .Q(
        n358) );
  EDFCNQD1 clk0_r_REG100_S1 ( .D(in[17]), .E(n17), .CP(wr_clk), .CDN(n3), .Q(
        n356) );
  EDFCNQD1 clk0_r_REG102_S1 ( .D(in[17]), .E(n23), .CP(wr_clk), .CDN(n3), .Q(
        n354) );
  EDFCNQD1 clk0_r_REG104_S1 ( .D(in[17]), .E(n21), .CP(wr_clk), .CDN(n3), .Q(
        n352) );
  EDFCNQD1 clk0_r_REG106_S1 ( .D(in[17]), .E(n2), .CP(wr_clk), .CDN(n3), .Q(
        n350) );
  EDFCNQD1 clk0_r_REG108_S1 ( .D(in[17]), .E(net34914), .CP(wr_clk), .CDN(n5), 
        .Q(n348) );
  EDFCNQD1 clk0_r_REG110_S1 ( .D(in[17]), .E(net34860), .CP(wr_clk), .CDN(n3), 
        .Q(n346) );
  EDFCNQD1 clk0_r_REG112_S1 ( .D(in[16]), .E(n6), .CP(wr_clk), .CDN(n3), .Q(
        n344) );
  EDFCNQD1 clk0_r_REG114_S1 ( .D(in[16]), .E(n54), .CP(wr_clk), .CDN(n3), .Q(
        n342) );
  EDFCNQD1 clk0_r_REG116_S1 ( .D(in[16]), .E(n18), .CP(wr_clk), .CDN(n43), .Q(
        n340) );
  EDFCNQD1 clk0_r_REG118_S1 ( .D(in[16]), .E(n23), .CP(wr_clk), .CDN(n5), .Q(
        n338) );
  EDFCNQD1 clk0_r_REG120_S1 ( .D(in[16]), .E(n21), .CP(wr_clk), .CDN(n5), .Q(
        n336) );
  EDFCNQD1 clk0_r_REG122_S1 ( .D(in[16]), .E(n2), .CP(wr_clk), .CDN(n3), .Q(
        n334) );
  EDFCNQD1 clk0_r_REG124_S1 ( .D(in[16]), .E(net34914), .CP(wr_clk), .CDN(n3), 
        .Q(n332) );
  EDFCNQD1 clk0_r_REG126_S1 ( .D(in[16]), .E(net34860), .CP(wr_clk), .CDN(n3), 
        .Q(n330) );
  EDFCNQD1 clk0_r_REG128_S1 ( .D(in[15]), .E(n6), .CP(wr_clk), .CDN(n3), .Q(
        n328) );
  EDFCNQD1 clk0_r_REG130_S1 ( .D(in[15]), .E(n54), .CP(wr_clk), .CDN(n3), .Q(
        n326) );
  EDFCNQD1 clk0_r_REG132_S1 ( .D(in[15]), .E(N40), .CP(wr_clk), .CDN(n3), .Q(
        n324) );
  EDFCNQD1 clk0_r_REG134_S1 ( .D(in[15]), .E(n23), .CP(wr_clk), .CDN(n3), .Q(
        n322) );
  EDFCNQD1 clk0_r_REG136_S1 ( .D(in[15]), .E(n21), .CP(wr_clk), .CDN(n3), .Q(
        n320) );
  EDFCNQD1 clk0_r_REG138_S1 ( .D(in[15]), .E(n2), .CP(wr_clk), .CDN(n3), .Q(
        n318) );
  EDFCNQD1 clk0_r_REG140_S1 ( .D(in[15]), .E(net34914), .CP(wr_clk), .CDN(n52), 
        .Q(n316) );
  EDFCNQD1 clk0_r_REG142_S1 ( .D(in[15]), .E(net34860), .CP(wr_clk), .CDN(n52), 
        .Q(n314) );
  EDFCNQD1 clk0_r_REG144_S1 ( .D(in[14]), .E(n6), .CP(wr_clk), .CDN(n3), .Q(
        n312) );
  EDFCNQD1 clk0_r_REG146_S1 ( .D(in[14]), .E(n54), .CP(wr_clk), .CDN(n3), .Q(
        n310) );
  EDFCNQD1 clk0_r_REG148_S1 ( .D(in[14]), .E(N40), .CP(wr_clk), .CDN(n3), .Q(
        n308) );
  EDFCNQD1 clk0_r_REG150_S1 ( .D(in[14]), .E(n23), .CP(wr_clk), .CDN(n3), .Q(
        n306) );
  EDFCNQD1 clk0_r_REG152_S1 ( .D(in[14]), .E(n21), .CP(wr_clk), .CDN(n3), .Q(
        n304) );
  EDFCNQD1 clk0_r_REG154_S1 ( .D(in[14]), .E(n2), .CP(wr_clk), .CDN(n3), .Q(
        n302) );
  EDFCNQD1 clk0_r_REG156_S1 ( .D(in[14]), .E(net34914), .CP(wr_clk), .CDN(n3), 
        .Q(n300) );
  EDFCNQD1 clk0_r_REG158_S1 ( .D(in[14]), .E(net34860), .CP(wr_clk), .CDN(n3), 
        .Q(n298) );
  EDFCNQD1 clk0_r_REG160_S1 ( .D(in[13]), .E(n6), .CP(wr_clk), .CDN(n3), .Q(
        n296) );
  EDFCNQD1 clk0_r_REG162_S1 ( .D(in[13]), .E(n54), .CP(wr_clk), .CDN(n5), .Q(
        n294) );
  EDFCNQD1 clk0_r_REG166_S1 ( .D(in[13]), .E(n23), .CP(wr_clk), .CDN(n5), .Q(
        n290) );
  EDFCNQD1 clk0_r_REG168_S1 ( .D(in[13]), .E(n21), .CP(wr_clk), .CDN(n3), .Q(
        n288) );
  EDFCNQD1 clk0_r_REG170_S1 ( .D(in[13]), .E(n2), .CP(wr_clk), .CDN(n3), .Q(
        n286) );
  EDFCNQD1 clk0_r_REG172_S1 ( .D(in[13]), .E(net34914), .CP(wr_clk), .CDN(n3), 
        .Q(n284) );
  EDFCNQD1 clk0_r_REG174_S1 ( .D(in[13]), .E(net34860), .CP(wr_clk), .CDN(n3), 
        .Q(n282) );
  EDFCNQD1 clk0_r_REG176_S1 ( .D(in[12]), .E(n6), .CP(wr_clk), .CDN(n5), .Q(
        n280) );
  EDFCNQD1 clk0_r_REG178_S1 ( .D(in[12]), .E(n54), .CP(wr_clk), .CDN(n3), .Q(
        n278) );
  EDFCNQD1 clk0_r_REG182_S1 ( .D(in[12]), .E(n23), .CP(wr_clk), .CDN(n3), .Q(
        n274) );
  EDFCNQD1 clk0_r_REG184_S1 ( .D(in[12]), .E(n21), .CP(wr_clk), .CDN(n3), .Q(
        n272) );
  EDFCNQD1 clk0_r_REG186_S1 ( .D(in[12]), .E(n2), .CP(wr_clk), .CDN(n5), .Q(
        n270) );
  EDFCNQD1 clk0_r_REG188_S1 ( .D(in[12]), .E(net34914), .CP(wr_clk), .CDN(n5), 
        .Q(n268) );
  EDFCNQD1 clk0_r_REG190_S1 ( .D(in[12]), .E(net34860), .CP(wr_clk), .CDN(n5), 
        .Q(n266) );
  EDFCNQD1 clk0_r_REG192_S1 ( .D(in[11]), .E(n6), .CP(wr_clk), .CDN(n5), .Q(
        n264) );
  EDFCNQD1 clk0_r_REG194_S1 ( .D(in[11]), .E(n54), .CP(wr_clk), .CDN(n5), .Q(
        n262) );
  EDFCNQD1 clk0_r_REG196_S1 ( .D(in[11]), .E(N40), .CP(wr_clk), .CDN(n5), .Q(
        n260) );
  EDFCNQD1 clk0_r_REG198_S1 ( .D(in[11]), .E(n23), .CP(wr_clk), .CDN(n5), .Q(
        n258) );
  EDFCNQD1 clk0_r_REG200_S1 ( .D(in[11]), .E(n21), .CP(wr_clk), .CDN(n5), .Q(
        n256) );
  EDFCNQD1 clk0_r_REG202_S1 ( .D(in[11]), .E(n2), .CP(wr_clk), .CDN(n3), .Q(
        n254) );
  EDFCNQD1 clk0_r_REG204_S1 ( .D(in[11]), .E(net34914), .CP(wr_clk), .CDN(n3), 
        .Q(n252) );
  EDFCNQD1 clk0_r_REG206_S1 ( .D(in[11]), .E(net34860), .CP(wr_clk), .CDN(n3), 
        .Q(n250) );
  EDFCNQD1 clk0_r_REG208_S1 ( .D(in[10]), .E(n6), .CP(wr_clk), .CDN(n3), .Q(
        n248) );
  EDFCNQD1 clk0_r_REG210_S1 ( .D(in[10]), .E(n54), .CP(wr_clk), .CDN(n3), .Q(
        n246) );
  EDFCNQD1 clk0_r_REG212_S1 ( .D(in[10]), .E(N40), .CP(wr_clk), .CDN(n3), .Q(
        n244) );
  EDFCNQD1 clk0_r_REG214_S1 ( .D(in[10]), .E(n23), .CP(wr_clk), .CDN(n3), .Q(
        n242) );
  EDFCNQD1 clk0_r_REG216_S1 ( .D(in[10]), .E(n21), .CP(wr_clk), .CDN(n3), .Q(
        n240) );
  EDFCNQD1 clk0_r_REG218_S1 ( .D(in[10]), .E(n2), .CP(wr_clk), .CDN(n3), .Q(
        n238) );
  EDFCNQD1 clk0_r_REG220_S1 ( .D(in[10]), .E(net34914), .CP(wr_clk), .CDN(n5), 
        .Q(n236) );
  EDFCNQD1 clk0_r_REG222_S1 ( .D(in[10]), .E(net34860), .CP(wr_clk), .CDN(n5), 
        .Q(n234) );
  EDFCNQD1 clk0_r_REG224_S1 ( .D(in[9]), .E(n6), .CP(wr_clk), .CDN(n5), .Q(
        n232) );
  EDFCNQD1 clk0_r_REG226_S1 ( .D(in[9]), .E(n54), .CP(wr_clk), .CDN(n5), .Q(
        n230) );
  EDFCNQD1 clk0_r_REG228_S1 ( .D(in[9]), .E(N40), .CP(wr_clk), .CDN(n43), .Q(
        n228) );
  EDFCNQD1 clk0_r_REG230_S1 ( .D(in[9]), .E(n23), .CP(wr_clk), .CDN(n3), .Q(
        n226) );
  EDFCNQD1 clk0_r_REG232_S1 ( .D(in[9]), .E(n21), .CP(wr_clk), .CDN(n53), .Q(
        n224) );
  EDFCNQD1 clk0_r_REG234_S1 ( .D(in[9]), .E(n2), .CP(wr_clk), .CDN(n53), .Q(
        n222) );
  EDFCNQD1 clk0_r_REG236_S1 ( .D(in[9]), .E(net34914), .CP(wr_clk), .CDN(n3), 
        .Q(n220) );
  EDFCNQD1 clk0_r_REG238_S1 ( .D(in[9]), .E(net34860), .CP(wr_clk), .CDN(n3), 
        .Q(n218) );
  EDFCNQD1 clk0_r_REG240_S1 ( .D(in[8]), .E(n6), .CP(wr_clk), .CDN(n53), .Q(
        n216) );
  EDFCNQD1 clk0_r_REG242_S1 ( .D(in[8]), .E(n54), .CP(wr_clk), .CDN(n5), .Q(
        n214) );
  EDFCNQD1 clk0_r_REG244_S1 ( .D(in[8]), .E(N40), .CP(wr_clk), .CDN(n43), .Q(
        n212) );
  EDFCNQD1 clk0_r_REG246_S1 ( .D(in[8]), .E(n23), .CP(wr_clk), .CDN(n5), .Q(
        n210) );
  EDFCNQD1 clk0_r_REG248_S1 ( .D(in[8]), .E(n21), .CP(wr_clk), .CDN(n3), .Q(
        n208) );
  EDFCNQD1 clk0_r_REG250_S1 ( .D(in[8]), .E(n2), .CP(wr_clk), .CDN(n3), .Q(
        n206) );
  EDFCNQD1 clk0_r_REG252_S1 ( .D(in[8]), .E(net34914), .CP(wr_clk), .CDN(n5), 
        .Q(n204) );
  EDFCNQD1 clk0_r_REG254_S1 ( .D(in[8]), .E(net34860), .CP(wr_clk), .CDN(n3), 
        .Q(n202) );
  EDFCNQD1 clk0_r_REG256_S1 ( .D(in[7]), .E(n6), .CP(wr_clk), .CDN(n3), .Q(
        n200) );
  EDFCNQD1 clk0_r_REG258_S1 ( .D(in[7]), .E(n54), .CP(wr_clk), .CDN(n3), .Q(
        n198) );
  EDFCNQD1 clk0_r_REG260_S1 ( .D(in[7]), .E(N40), .CP(wr_clk), .CDN(n3), .Q(
        n196) );
  EDFCNQD1 clk0_r_REG262_S1 ( .D(in[7]), .E(n23), .CP(wr_clk), .CDN(n3), .Q(
        n194) );
  EDFCNQD1 clk0_r_REG264_S1 ( .D(in[7]), .E(n21), .CP(wr_clk), .CDN(n3), .Q(
        n192) );
  EDFCNQD1 clk0_r_REG266_S1 ( .D(in[7]), .E(n2), .CP(wr_clk), .CDN(n5), .Q(
        n190) );
  EDFCNQD1 clk0_r_REG268_S1 ( .D(in[7]), .E(net34914), .CP(wr_clk), .CDN(n53), 
        .Q(n188) );
  EDFCNQD1 clk0_r_REG270_S1 ( .D(in[7]), .E(net34860), .CP(wr_clk), .CDN(n3), 
        .Q(n186) );
  EDFCNQD1 clk0_r_REG272_S1 ( .D(in[6]), .E(n6), .CP(wr_clk), .CDN(n3), .Q(
        n184) );
  EDFCNQD1 clk0_r_REG274_S1 ( .D(in[6]), .E(n54), .CP(wr_clk), .CDN(n3), .Q(
        n182) );
  EDFCNQD1 clk0_r_REG278_S1 ( .D(in[6]), .E(n23), .CP(wr_clk), .CDN(n3), .Q(
        n178) );
  EDFCNQD1 clk0_r_REG280_S1 ( .D(in[6]), .E(n21), .CP(wr_clk), .CDN(n3), .Q(
        n176) );
  EDFCNQD1 clk0_r_REG282_S1 ( .D(in[6]), .E(n2), .CP(wr_clk), .CDN(n52), .Q(
        n174) );
  EDFCNQD1 clk0_r_REG284_S1 ( .D(in[6]), .E(net34914), .CP(wr_clk), .CDN(n5), 
        .Q(n172) );
  EDFCNQD1 clk0_r_REG286_S1 ( .D(in[6]), .E(net34860), .CP(wr_clk), .CDN(n3), 
        .Q(n170) );
  EDFCNQD1 clk0_r_REG288_S1 ( .D(in[5]), .E(n6), .CP(wr_clk), .CDN(n3), .Q(
        n168) );
  EDFCNQD1 clk0_r_REG290_S1 ( .D(in[5]), .E(n54), .CP(wr_clk), .CDN(n5), .Q(
        n166) );
  EDFCNQD1 clk0_r_REG294_S1 ( .D(in[5]), .E(n23), .CP(wr_clk), .CDN(n5), .Q(
        n162) );
  EDFCNQD1 clk0_r_REG296_S1 ( .D(in[5]), .E(n21), .CP(wr_clk), .CDN(n3), .Q(
        n160) );
  EDFCNQD1 clk0_r_REG298_S1 ( .D(in[5]), .E(n2), .CP(wr_clk), .CDN(n3), .Q(
        n158) );
  EDFCNQD1 clk0_r_REG300_S1 ( .D(in[5]), .E(net34914), .CP(wr_clk), .CDN(n3), 
        .Q(n156) );
  EDFCNQD1 clk0_r_REG302_S1 ( .D(in[5]), .E(net34860), .CP(wr_clk), .CDN(n52), 
        .Q(n154) );
  EDFCNQD1 clk0_r_REG304_S1 ( .D(in[4]), .E(n6), .CP(wr_clk), .CDN(n43), .Q(
        n152) );
  EDFCNQD1 clk0_r_REG306_S1 ( .D(in[4]), .E(n54), .CP(wr_clk), .CDN(n53), .Q(
        n150) );
  EDFCNQD1 clk0_r_REG310_S1 ( .D(in[4]), .E(n23), .CP(wr_clk), .CDN(n52), .Q(
        n146) );
  EDFCNQD1 clk0_r_REG312_S1 ( .D(in[4]), .E(n21), .CP(wr_clk), .CDN(n52), .Q(
        n144) );
  EDFCNQD1 clk0_r_REG314_S1 ( .D(in[4]), .E(n2), .CP(wr_clk), .CDN(n52), .Q(
        n142) );
  EDFCNQD1 clk0_r_REG316_S1 ( .D(in[4]), .E(net34914), .CP(wr_clk), .CDN(n5), 
        .Q(n140) );
  EDFCNQD1 clk0_r_REG318_S1 ( .D(in[4]), .E(net34860), .CP(wr_clk), .CDN(n3), 
        .Q(n138) );
  EDFCNQD1 clk0_r_REG320_S1 ( .D(in[3]), .E(n6), .CP(wr_clk), .CDN(n3), .Q(
        n136) );
  EDFCNQD1 clk0_r_REG322_S1 ( .D(in[3]), .E(n54), .CP(wr_clk), .CDN(n53), .Q(
        n134) );
  EDFCNQD1 clk0_r_REG324_S1 ( .D(in[3]), .E(n18), .CP(wr_clk), .CDN(n3), .Q(
        n132) );
  EDFCNQD1 clk0_r_REG326_S1 ( .D(in[3]), .E(n23), .CP(wr_clk), .CDN(n3), .Q(
        n130) );
  EDFCNQD1 clk0_r_REG328_S1 ( .D(in[3]), .E(n21), .CP(wr_clk), .CDN(n3), .Q(
        n128) );
  EDFCNQD1 clk0_r_REG330_S1 ( .D(in[3]), .E(n2), .CP(wr_clk), .CDN(n5), .Q(
        n126) );
  EDFCNQD1 clk0_r_REG332_S1 ( .D(in[3]), .E(net34914), .CP(wr_clk), .CDN(n3), 
        .Q(n124) );
  EDFCNQD1 clk0_r_REG334_S1 ( .D(in[3]), .E(net34860), .CP(wr_clk), .CDN(n3), 
        .Q(n122) );
  EDFCNQD1 clk0_r_REG336_S1 ( .D(in[2]), .E(n6), .CP(wr_clk), .CDN(n3), .Q(
        n120) );
  EDFCNQD1 clk0_r_REG338_S1 ( .D(in[2]), .E(n54), .CP(wr_clk), .CDN(n5), .Q(
        n118) );
  EDFCNQD1 clk0_r_REG342_S1 ( .D(in[2]), .E(n23), .CP(wr_clk), .CDN(n53), .Q(
        n114) );
  EDFCNQD1 clk0_r_REG344_S1 ( .D(in[2]), .E(n21), .CP(wr_clk), .CDN(n3), .Q(
        n112) );
  EDFCNQD1 clk0_r_REG346_S1 ( .D(in[2]), .E(n2), .CP(wr_clk), .CDN(n5), .Q(
        n110) );
  EDFCNQD1 clk0_r_REG348_S1 ( .D(in[2]), .E(net34914), .CP(wr_clk), .CDN(n5), 
        .Q(n108) );
  EDFCNQD1 clk0_r_REG350_S1 ( .D(in[2]), .E(net34860), .CP(wr_clk), .CDN(n3), 
        .Q(n106) );
  EDFCNQD1 clk0_r_REG352_S1 ( .D(in[1]), .E(n6), .CP(wr_clk), .CDN(n5), .Q(
        n104) );
  EDFCNQD1 clk0_r_REG354_S1 ( .D(in[1]), .E(n54), .CP(wr_clk), .CDN(n3), .Q(
        n102) );
  EDFCNQD1 clk0_r_REG358_S1 ( .D(in[1]), .E(n23), .CP(wr_clk), .CDN(n3), .Q(
        n98) );
  EDFCNQD1 clk0_r_REG360_S1 ( .D(in[1]), .E(n21), .CP(wr_clk), .CDN(n5), .Q(
        n96) );
  EDFCNQD1 clk0_r_REG362_S1 ( .D(in[1]), .E(n2), .CP(wr_clk), .CDN(n5), .Q(n94) );
  EDFCNQD1 clk0_r_REG364_S1 ( .D(in[1]), .E(net34914), .CP(wr_clk), .CDN(n3), 
        .Q(n92) );
  EDFCNQD1 clk0_r_REG366_S1 ( .D(in[1]), .E(net34860), .CP(wr_clk), .CDN(n53), 
        .Q(n90) );
  EDFCNQD1 clk0_r_REG368_S1 ( .D(in[0]), .E(n6), .CP(wr_clk), .CDN(n5), .Q(n88) );
  EDFCNQD1 clk0_r_REG370_S1 ( .D(in[0]), .E(n54), .CP(wr_clk), .CDN(n43), .Q(
        n86) );
  EDFCNQD1 clk0_r_REG374_S1 ( .D(in[0]), .E(n23), .CP(wr_clk), .CDN(n53), .Q(
        n82) );
  EDFCNQD1 clk0_r_REG376_S1 ( .D(in[0]), .E(n21), .CP(wr_clk), .CDN(n5), .Q(
        n80) );
  EDFCNQD1 clk0_r_REG378_S1 ( .D(in[0]), .E(n2), .CP(wr_clk), .CDN(n3), .Q(n78) );
  EDFCNQD1 clk0_r_REG380_S1 ( .D(in[0]), .E(net34914), .CP(wr_clk), .CDN(n3), 
        .Q(n76) );
  EDFCNQD1 clk0_r_REG382_S1 ( .D(in[0]), .E(net34860), .CP(wr_clk), .CDN(n5), 
        .Q(n74) );
  EDFCNQD1 clk0_r_REG1_S1 ( .D(in[23]), .E(n36), .CP(wr_clk), .CDN(n3), .Q(
        n455) );
  EDFCNQD1 clk0_r_REG3_S1 ( .D(in[23]), .E(n55), .CP(wr_clk), .CDN(n3), .Q(
        n453) );
  EDFCNQD1 clk0_r_REG5_S1 ( .D(in[23]), .E(n22), .CP(wr_clk), .CDN(n3), .Q(
        n451) );
  EDFCNQD1 clk0_r_REG7_S1 ( .D(in[23]), .E(N37), .CP(wr_clk), .CDN(n53), .Q(
        n449) );
  EDFCNQD1 clk0_r_REG9_S1 ( .D(in[23]), .E(n19), .CP(wr_clk), .CDN(n3), .Q(
        n447) );
  EDFCNQD1 clk0_r_REG13_S1 ( .D(in[23]), .E(net33754), .CP(wr_clk), .CDN(n43), 
        .Q(n443) );
  EDFCNQD1 clk0_r_REG17_S1 ( .D(in[22]), .E(n36), .CP(wr_clk), .CDN(n3), .Q(
        n439) );
  EDFCNQD1 clk0_r_REG19_S1 ( .D(in[22]), .E(n55), .CP(wr_clk), .CDN(n3), .Q(
        n437) );
  EDFCNQD1 clk0_r_REG21_S1 ( .D(in[22]), .E(n22), .CP(wr_clk), .CDN(n3), .Q(
        n435) );
  EDFCNQD1 clk0_r_REG23_S1 ( .D(in[22]), .E(N37), .CP(wr_clk), .CDN(n3), .Q(
        n433) );
  EDFCNQD1 clk0_r_REG25_S1 ( .D(in[22]), .E(n19), .CP(wr_clk), .CDN(n3), .Q(
        n431) );
  EDFCNQD1 clk0_r_REG29_S1 ( .D(in[22]), .E(net33754), .CP(wr_clk), .CDN(n3), 
        .Q(n427) );
  EDFCNQD1 clk0_r_REG33_S1 ( .D(in[21]), .E(n36), .CP(wr_clk), .CDN(n3), .Q(
        n423) );
  EDFCNQD1 clk0_r_REG35_S1 ( .D(in[21]), .E(n55), .CP(wr_clk), .CDN(n5), .Q(
        n421) );
  EDFCNQD1 clk0_r_REG37_S1 ( .D(in[21]), .E(n22), .CP(wr_clk), .CDN(n3), .Q(
        n419) );
  EDFCNQD1 clk0_r_REG39_S1 ( .D(in[21]), .E(N37), .CP(wr_clk), .CDN(n3), .Q(
        n417) );
  EDFCNQD1 clk0_r_REG41_S1 ( .D(in[21]), .E(n19), .CP(wr_clk), .CDN(n3), .Q(
        n415) );
  EDFCNQD1 clk0_r_REG43_S1 ( .D(in[21]), .E(net34680), .CP(wr_clk), .CDN(n3), 
        .Q(n413) );
  EDFCNQD1 clk0_r_REG45_S1 ( .D(in[21]), .E(net33754), .CP(wr_clk), .CDN(n3), 
        .Q(n411) );
  EDFCNQD1 clk0_r_REG47_S1 ( .D(in[21]), .E(net34726), .CP(wr_clk), .CDN(n3), 
        .Q(n409) );
  EDFCNQD1 clk0_r_REG49_S1 ( .D(in[20]), .E(n36), .CP(wr_clk), .CDN(n3), .Q(
        n407) );
  EDFCNQD1 clk0_r_REG51_S1 ( .D(in[20]), .E(n55), .CP(wr_clk), .CDN(n5), .Q(
        n405) );
  EDFCNQD1 clk0_r_REG53_S1 ( .D(in[20]), .E(n22), .CP(wr_clk), .CDN(n3), .Q(
        n403) );
  EDFCNQD1 clk0_r_REG55_S1 ( .D(in[20]), .E(N37), .CP(wr_clk), .CDN(n5), .Q(
        n401) );
  EDFCNQD1 clk0_r_REG57_S1 ( .D(in[20]), .E(n19), .CP(wr_clk), .CDN(n3), .Q(
        n399) );
  EDFCNQD1 clk0_r_REG59_S1 ( .D(in[20]), .E(net34680), .CP(wr_clk), .CDN(n53), 
        .Q(n397) );
  EDFCNQD1 clk0_r_REG61_S1 ( .D(in[20]), .E(net33754), .CP(wr_clk), .CDN(n43), 
        .Q(n395) );
  EDFCNQD1 clk0_r_REG63_S1 ( .D(in[20]), .E(net34726), .CP(wr_clk), .CDN(n3), 
        .Q(n393) );
  EDFCNQD1 clk0_r_REG65_S1 ( .D(in[19]), .E(n36), .CP(wr_clk), .CDN(n53), .Q(
        n391) );
  EDFCNQD1 clk0_r_REG67_S1 ( .D(in[19]), .E(n55), .CP(wr_clk), .CDN(n53), .Q(
        n389) );
  EDFCNQD1 clk0_r_REG69_S1 ( .D(in[19]), .E(n22), .CP(wr_clk), .CDN(n53), .Q(
        n387) );
  EDFCNQD1 clk0_r_REG71_S1 ( .D(in[19]), .E(N37), .CP(wr_clk), .CDN(n53), .Q(
        n385) );
  EDFCNQD1 clk0_r_REG73_S1 ( .D(in[19]), .E(n19), .CP(wr_clk), .CDN(n53), .Q(
        n383) );
  EDFCNQD1 clk0_r_REG75_S1 ( .D(in[19]), .E(net34680), .CP(wr_clk), .CDN(n53), 
        .Q(n381) );
  EDFCNQD1 clk0_r_REG77_S1 ( .D(in[19]), .E(net33754), .CP(wr_clk), .CDN(n3), 
        .Q(n379) );
  EDFCNQD1 clk0_r_REG81_S1 ( .D(in[18]), .E(n36), .CP(wr_clk), .CDN(n3), .Q(
        n375) );
  EDFCNQD1 clk0_r_REG83_S1 ( .D(in[18]), .E(n55), .CP(wr_clk), .CDN(n5), .Q(
        n373) );
  EDFCNQD1 clk0_r_REG85_S1 ( .D(in[18]), .E(n22), .CP(wr_clk), .CDN(n3), .Q(
        n371) );
  EDFCNQD1 clk0_r_REG87_S1 ( .D(in[18]), .E(N37), .CP(wr_clk), .CDN(n53), .Q(
        n369) );
  EDFCNQD1 clk0_r_REG89_S1 ( .D(in[18]), .E(n19), .CP(wr_clk), .CDN(n3), .Q(
        n367) );
  EDFCNQD1 clk0_r_REG91_S1 ( .D(in[18]), .E(net34680), .CP(wr_clk), .CDN(n53), 
        .Q(n365) );
  EDFCNQD1 clk0_r_REG93_S1 ( .D(in[18]), .E(net33754), .CP(wr_clk), .CDN(n53), 
        .Q(n363) );
  EDFCNQD1 clk0_r_REG95_S1 ( .D(in[18]), .E(net34726), .CP(wr_clk), .CDN(n53), 
        .Q(n361) );
  EDFCNQD1 clk0_r_REG97_S1 ( .D(in[17]), .E(n36), .CP(wr_clk), .CDN(n53), .Q(
        n359) );
  EDFCNQD1 clk0_r_REG99_S1 ( .D(in[17]), .E(n55), .CP(wr_clk), .CDN(n5), .Q(
        n357) );
  EDFCNQD1 clk0_r_REG101_S1 ( .D(in[17]), .E(n22), .CP(wr_clk), .CDN(n53), .Q(
        n355) );
  EDFCNQD1 clk0_r_REG103_S1 ( .D(in[17]), .E(N37), .CP(wr_clk), .CDN(n5), .Q(
        n353) );
  EDFCNQD1 clk0_r_REG105_S1 ( .D(in[17]), .E(n19), .CP(wr_clk), .CDN(n3), .Q(
        n351) );
  EDFCNQD1 clk0_r_REG107_S1 ( .D(in[17]), .E(net34680), .CP(wr_clk), .CDN(n5), 
        .Q(n349) );
  EDFCNQD1 clk0_r_REG109_S1 ( .D(in[17]), .E(net33754), .CP(wr_clk), .CDN(n3), 
        .Q(n347) );
  EDFCNQD1 clk0_r_REG111_S1 ( .D(in[17]), .E(net34726), .CP(wr_clk), .CDN(n3), 
        .Q(n345) );
  EDFCNQD1 clk0_r_REG113_S1 ( .D(in[16]), .E(n36), .CP(wr_clk), .CDN(n52), .Q(
        n343) );
  EDFCNQD1 clk0_r_REG115_S1 ( .D(in[16]), .E(n55), .CP(wr_clk), .CDN(n52), .Q(
        n341) );
  EDFCNQD1 clk0_r_REG117_S1 ( .D(in[16]), .E(n22), .CP(wr_clk), .CDN(n3), .Q(
        n339) );
  EDFCNQD1 clk0_r_REG119_S1 ( .D(in[16]), .E(N37), .CP(wr_clk), .CDN(n3), .Q(
        n337) );
  EDFCNQD1 clk0_r_REG121_S1 ( .D(in[16]), .E(n19), .CP(wr_clk), .CDN(n3), .Q(
        n335) );
  EDFCNQD1 clk0_r_REG123_S1 ( .D(in[16]), .E(net34680), .CP(wr_clk), .CDN(n53), 
        .Q(n333) );
  EDFCNQD1 clk0_r_REG125_S1 ( .D(in[16]), .E(net33754), .CP(wr_clk), .CDN(n5), 
        .Q(n331) );
  EDFCNQD1 clk0_r_REG127_S1 ( .D(in[16]), .E(net34726), .CP(wr_clk), .CDN(n3), 
        .Q(n329) );
  EDFCNQD1 clk0_r_REG129_S1 ( .D(in[15]), .E(n36), .CP(wr_clk), .CDN(n3), .Q(
        n327) );
  EDFCNQD1 clk0_r_REG131_S1 ( .D(in[15]), .E(n55), .CP(wr_clk), .CDN(n3), .Q(
        n325) );
  EDFCNQD1 clk0_r_REG133_S1 ( .D(in[15]), .E(n22), .CP(wr_clk), .CDN(n52), .Q(
        n323) );
  EDFCNQD1 clk0_r_REG135_S1 ( .D(in[15]), .E(N37), .CP(wr_clk), .CDN(n52), .Q(
        n321) );
  EDFCNQD1 clk0_r_REG137_S1 ( .D(in[15]), .E(n19), .CP(wr_clk), .CDN(n52), .Q(
        n319) );
  EDFCNQD1 clk0_r_REG139_S1 ( .D(in[15]), .E(net34680), .CP(wr_clk), .CDN(n52), 
        .Q(n317) );
  EDFCNQD1 clk0_r_REG141_S1 ( .D(in[15]), .E(net33754), .CP(wr_clk), .CDN(n52), 
        .Q(n315) );
  EDFCNQD1 clk0_r_REG143_S1 ( .D(in[15]), .E(net34726), .CP(wr_clk), .CDN(n52), 
        .Q(n313) );
  EDFCNQD1 clk0_r_REG145_S1 ( .D(in[14]), .E(n36), .CP(wr_clk), .CDN(n3), .Q(
        n311) );
  EDFCNQD1 clk0_r_REG147_S1 ( .D(in[14]), .E(n55), .CP(wr_clk), .CDN(n3), .Q(
        n309) );
  EDFCNQD1 clk0_r_REG149_S1 ( .D(in[14]), .E(n22), .CP(wr_clk), .CDN(n3), .Q(
        n307) );
  EDFCNQD1 clk0_r_REG151_S1 ( .D(in[14]), .E(N37), .CP(wr_clk), .CDN(n3), .Q(
        n305) );
  EDFCNQD1 clk0_r_REG153_S1 ( .D(in[14]), .E(n19), .CP(wr_clk), .CDN(n3), .Q(
        n303) );
  EDFCNQD1 clk0_r_REG155_S1 ( .D(in[14]), .E(net34680), .CP(wr_clk), .CDN(n3), 
        .Q(n301) );
  EDFCNQD1 clk0_r_REG157_S1 ( .D(in[14]), .E(net33754), .CP(wr_clk), .CDN(n3), 
        .Q(n299) );
  EDFCNQD1 clk0_r_REG159_S1 ( .D(in[14]), .E(net34726), .CP(wr_clk), .CDN(n3), 
        .Q(n297) );
  EDFCNQD1 clk0_r_REG161_S1 ( .D(in[13]), .E(n36), .CP(wr_clk), .CDN(n5), .Q(
        n295) );
  EDFCNQD1 clk0_r_REG163_S1 ( .D(in[13]), .E(n55), .CP(wr_clk), .CDN(n5), .Q(
        n293) );
  EDFCNQD1 clk0_r_REG165_S1 ( .D(in[13]), .E(n22), .CP(wr_clk), .CDN(n5), .Q(
        n291) );
  EDFCNQD1 clk0_r_REG167_S1 ( .D(in[13]), .E(N37), .CP(wr_clk), .CDN(n5), .Q(
        n289) );
  EDFCNQD1 clk0_r_REG169_S1 ( .D(in[13]), .E(n19), .CP(wr_clk), .CDN(n3), .Q(
        n287) );
  EDFCNQD1 clk0_r_REG171_S1 ( .D(in[13]), .E(net34680), .CP(wr_clk), .CDN(n3), 
        .Q(n285) );
  EDFCNQD1 clk0_r_REG173_S1 ( .D(in[13]), .E(net33754), .CP(wr_clk), .CDN(n3), 
        .Q(n283) );
  EDFCNQD1 clk0_r_REG175_S1 ( .D(in[13]), .E(net34726), .CP(wr_clk), .CDN(n3), 
        .Q(n281) );
  EDFCNQD1 clk0_r_REG177_S1 ( .D(in[12]), .E(n36), .CP(wr_clk), .CDN(n3), .Q(
        n279) );
  EDFCNQD1 clk0_r_REG179_S1 ( .D(in[12]), .E(n55), .CP(wr_clk), .CDN(n3), .Q(
        n277) );
  EDFCNQD1 clk0_r_REG181_S1 ( .D(in[12]), .E(n22), .CP(wr_clk), .CDN(n3), .Q(
        n275) );
  EDFCNQD1 clk0_r_REG183_S1 ( .D(in[12]), .E(N37), .CP(wr_clk), .CDN(n3), .Q(
        n273) );
  EDFCNQD1 clk0_r_REG185_S1 ( .D(in[12]), .E(n19), .CP(wr_clk), .CDN(n5), .Q(
        n271) );
  EDFCNQD1 clk0_r_REG187_S1 ( .D(in[12]), .E(net34680), .CP(wr_clk), .CDN(n5), 
        .Q(n269) );
  EDFCNQD1 clk0_r_REG189_S1 ( .D(in[12]), .E(net33754), .CP(wr_clk), .CDN(n5), 
        .Q(n267) );
  EDFCNQD1 clk0_r_REG191_S1 ( .D(in[12]), .E(net34726), .CP(wr_clk), .CDN(n5), 
        .Q(n265) );
  EDFCNQD1 clk0_r_REG193_S1 ( .D(in[11]), .E(n36), .CP(wr_clk), .CDN(n5), .Q(
        n263) );
  EDFCNQD1 clk0_r_REG195_S1 ( .D(in[11]), .E(n35), .CP(wr_clk), .CDN(n5), .Q(
        n261) );
  EDFCNQD1 clk0_r_REG197_S1 ( .D(in[11]), .E(n22), .CP(wr_clk), .CDN(n5), .Q(
        n259) );
  EDFCNQD1 clk0_r_REG199_S1 ( .D(in[11]), .E(N37), .CP(wr_clk), .CDN(n5), .Q(
        n257) );
  EDFCNQD1 clk0_r_REG201_S1 ( .D(in[11]), .E(n19), .CP(wr_clk), .CDN(n5), .Q(
        n255) );
  EDFCNQD1 clk0_r_REG203_S1 ( .D(in[11]), .E(net34680), .CP(wr_clk), .CDN(n3), 
        .Q(n253) );
  EDFCNQD1 clk0_r_REG205_S1 ( .D(in[11]), .E(net33754), .CP(wr_clk), .CDN(n3), 
        .Q(n251) );
  EDFCNQD1 clk0_r_REG207_S1 ( .D(in[11]), .E(net34726), .CP(wr_clk), .CDN(n3), 
        .Q(n249) );
  EDFCNQD1 clk0_r_REG209_S1 ( .D(in[10]), .E(n36), .CP(wr_clk), .CDN(n3), .Q(
        n247) );
  EDFCNQD1 clk0_r_REG211_S1 ( .D(in[10]), .E(n35), .CP(wr_clk), .CDN(n5), .Q(
        n245) );
  EDFCNQD1 clk0_r_REG213_S1 ( .D(in[10]), .E(n22), .CP(wr_clk), .CDN(n5), .Q(
        n243) );
  EDFCNQD1 clk0_r_REG215_S1 ( .D(in[10]), .E(N37), .CP(wr_clk), .CDN(n3), .Q(
        n241) );
  EDFCNQD1 clk0_r_REG217_S1 ( .D(in[10]), .E(n19), .CP(wr_clk), .CDN(n3), .Q(
        n239) );
  EDFCNQD1 clk0_r_REG219_S1 ( .D(in[10]), .E(net34680), .CP(wr_clk), .CDN(n5), 
        .Q(n237) );
  EDFCNQD1 clk0_r_REG221_S1 ( .D(in[10]), .E(net33754), .CP(wr_clk), .CDN(n5), 
        .Q(n235) );
  EDFCNQD1 clk0_r_REG223_S1 ( .D(in[10]), .E(net34726), .CP(wr_clk), .CDN(n5), 
        .Q(n233) );
  EDFCNQD1 clk0_r_REG225_S1 ( .D(in[9]), .E(n36), .CP(wr_clk), .CDN(n3), .Q(
        n231) );
  EDFCNQD1 clk0_r_REG227_S1 ( .D(in[9]), .E(n35), .CP(wr_clk), .CDN(n53), .Q(
        n229) );
  EDFCNQD1 clk0_r_REG229_S1 ( .D(in[9]), .E(n22), .CP(wr_clk), .CDN(n5), .Q(
        n227) );
  EDFCNQD1 clk0_r_REG231_S1 ( .D(in[9]), .E(N37), .CP(wr_clk), .CDN(n3), .Q(
        n225) );
  EDFCNQD1 clk0_r_REG233_S1 ( .D(in[9]), .E(n19), .CP(wr_clk), .CDN(n5), .Q(
        n223) );
  EDFCNQD1 clk0_r_REG235_S1 ( .D(in[9]), .E(net34680), .CP(wr_clk), .CDN(n5), 
        .Q(n221) );
  EDFCNQD1 clk0_r_REG237_S1 ( .D(in[9]), .E(net33754), .CP(wr_clk), .CDN(n53), 
        .Q(n219) );
  EDFCNQD1 clk0_r_REG239_S1 ( .D(in[9]), .E(net34726), .CP(wr_clk), .CDN(n3), 
        .Q(n217) );
  EDFCNQD1 clk0_r_REG241_S1 ( .D(in[8]), .E(n36), .CP(wr_clk), .CDN(n3), .Q(
        n215) );
  EDFCNQD1 clk0_r_REG243_S1 ( .D(in[8]), .E(n35), .CP(wr_clk), .CDN(n5), .Q(
        n213) );
  EDFCNQD1 clk0_r_REG245_S1 ( .D(in[8]), .E(n22), .CP(wr_clk), .CDN(n3), .Q(
        n211) );
  EDFCNQD1 clk0_r_REG247_S1 ( .D(in[8]), .E(N37), .CP(wr_clk), .CDN(n3), .Q(
        n209) );
  EDFCNQD1 clk0_r_REG249_S1 ( .D(in[8]), .E(n19), .CP(wr_clk), .CDN(n3), .Q(
        n207) );
  EDFCNQD1 clk0_r_REG251_S1 ( .D(in[8]), .E(net34680), .CP(wr_clk), .CDN(n52), 
        .Q(n205) );
  EDFCNQD1 clk0_r_REG253_S1 ( .D(in[8]), .E(net33754), .CP(wr_clk), .CDN(n3), 
        .Q(n203) );
  EDFCNQD1 clk0_r_REG255_S1 ( .D(in[8]), .E(net34726), .CP(wr_clk), .CDN(n5), 
        .Q(n201) );
  EDFCNQD1 clk0_r_REG257_S1 ( .D(in[7]), .E(n36), .CP(wr_clk), .CDN(n5), .Q(
        n199) );
  EDFCNQD1 clk0_r_REG259_S1 ( .D(in[7]), .E(n35), .CP(wr_clk), .CDN(n3), .Q(
        n197) );
  EDFCNQD1 clk0_r_REG261_S1 ( .D(in[7]), .E(n22), .CP(wr_clk), .CDN(n3), .Q(
        n195) );
  EDFCNQD1 clk0_r_REG263_S1 ( .D(in[7]), .E(N37), .CP(wr_clk), .CDN(n3), .Q(
        n193) );
  EDFCNQD1 clk0_r_REG265_S1 ( .D(in[7]), .E(n19), .CP(wr_clk), .CDN(n3), .Q(
        n191) );
  EDFCNQD1 clk0_r_REG267_S1 ( .D(in[7]), .E(net34680), .CP(wr_clk), .CDN(n3), 
        .Q(n189) );
  EDFCNQD1 clk0_r_REG269_S1 ( .D(in[7]), .E(net33754), .CP(wr_clk), .CDN(n53), 
        .Q(n187) );
  EDFCNQD1 clk0_r_REG271_S1 ( .D(in[7]), .E(net34726), .CP(wr_clk), .CDN(n3), 
        .Q(n185) );
  EDFCNQD1 clk0_r_REG273_S1 ( .D(in[6]), .E(n36), .CP(wr_clk), .CDN(n5), .Q(
        n183) );
  EDFCNQD1 clk0_r_REG275_S1 ( .D(in[6]), .E(n35), .CP(wr_clk), .CDN(n5), .Q(
        n181) );
  EDFCNQD1 clk0_r_REG277_S1 ( .D(in[6]), .E(n22), .CP(wr_clk), .CDN(n3), .Q(
        n179) );
  EDFCNQD1 clk0_r_REG279_S1 ( .D(in[6]), .E(N37), .CP(wr_clk), .CDN(n3), .Q(
        n177) );
  EDFCNQD1 clk0_r_REG281_S1 ( .D(in[6]), .E(n19), .CP(wr_clk), .CDN(n3), .Q(
        n175) );
  EDFCNQD1 clk0_r_REG283_S1 ( .D(in[6]), .E(net34680), .CP(wr_clk), .CDN(n3), 
        .Q(n173) );
  EDFCNQD1 clk0_r_REG285_S1 ( .D(in[6]), .E(net33754), .CP(wr_clk), .CDN(n3), 
        .Q(n171) );
  EDFCNQD1 clk0_r_REG287_S1 ( .D(in[6]), .E(net34726), .CP(wr_clk), .CDN(n3), 
        .Q(n169) );
  EDFCNQD1 clk0_r_REG289_S1 ( .D(in[5]), .E(n36), .CP(wr_clk), .CDN(n43), .Q(
        n167) );
  EDFCNQD1 clk0_r_REG291_S1 ( .D(in[5]), .E(n35), .CP(wr_clk), .CDN(n5), .Q(
        n165) );
  EDFCNQD1 clk0_r_REG293_S1 ( .D(in[5]), .E(n22), .CP(wr_clk), .CDN(n5), .Q(
        n163) );
  EDFCNQD1 clk0_r_REG295_S1 ( .D(in[5]), .E(N37), .CP(wr_clk), .CDN(n3), .Q(
        n161) );
  EDFCNQD1 clk0_r_REG297_S1 ( .D(in[5]), .E(n19), .CP(wr_clk), .CDN(n53), .Q(
        n159) );
  EDFCNQD1 clk0_r_REG299_S1 ( .D(in[5]), .E(net34680), .CP(wr_clk), .CDN(n5), 
        .Q(n157) );
  EDFCNQD1 clk0_r_REG301_S1 ( .D(in[5]), .E(net33754), .CP(wr_clk), .CDN(n53), 
        .Q(n155) );
  EDFCNQD1 clk0_r_REG303_S1 ( .D(in[5]), .E(net34726), .CP(wr_clk), .CDN(n3), 
        .Q(n153) );
  EDFCNQD1 clk0_r_REG305_S1 ( .D(in[4]), .E(n36), .CP(wr_clk), .CDN(n52), .Q(
        n151) );
  EDFCNQD1 clk0_r_REG307_S1 ( .D(in[4]), .E(n35), .CP(wr_clk), .CDN(n3), .Q(
        n149) );
  EDFCNQD1 clk0_r_REG309_S1 ( .D(in[4]), .E(n22), .CP(wr_clk), .CDN(n3), .Q(
        n147) );
  EDFCNQD1 clk0_r_REG311_S1 ( .D(in[4]), .E(N37), .CP(wr_clk), .CDN(n3), .Q(
        n145) );
  EDFCNQD1 clk0_r_REG313_S1 ( .D(in[4]), .E(n19), .CP(wr_clk), .CDN(n3), .Q(
        n143) );
  EDFCNQD1 clk0_r_REG315_S1 ( .D(in[4]), .E(net34680), .CP(wr_clk), .CDN(n3), 
        .Q(n141) );
  EDFCNQD1 clk0_r_REG317_S1 ( .D(in[4]), .E(net33754), .CP(wr_clk), .CDN(n5), 
        .Q(n139) );
  EDFCNQD1 clk0_r_REG319_S1 ( .D(in[4]), .E(net34726), .CP(wr_clk), .CDN(n3), 
        .Q(n137) );
  EDFCNQD1 clk0_r_REG321_S1 ( .D(in[3]), .E(n36), .CP(wr_clk), .CDN(n3), .Q(
        n135) );
  EDFCNQD1 clk0_r_REG323_S1 ( .D(in[3]), .E(n35), .CP(wr_clk), .CDN(n3), .Q(
        n133) );
  EDFCNQD1 clk0_r_REG325_S1 ( .D(in[3]), .E(n22), .CP(wr_clk), .CDN(n53), .Q(
        n131) );
  EDFCNQD1 clk0_r_REG327_S1 ( .D(in[3]), .E(N37), .CP(wr_clk), .CDN(n3), .Q(
        n129) );
  EDFCNQD1 clk0_r_REG329_S1 ( .D(in[3]), .E(n19), .CP(wr_clk), .CDN(n3), .Q(
        n127) );
  EDFCNQD1 clk0_r_REG331_S1 ( .D(in[3]), .E(net34680), .CP(wr_clk), .CDN(n3), 
        .Q(n125) );
  EDFCNQD1 clk0_r_REG333_S1 ( .D(in[3]), .E(net33754), .CP(wr_clk), .CDN(n3), 
        .Q(n123) );
  EDFCNQD1 clk0_r_REG335_S1 ( .D(in[3]), .E(net34726), .CP(wr_clk), .CDN(n3), 
        .Q(n121) );
  EDFCNQD1 clk0_r_REG337_S1 ( .D(in[2]), .E(n36), .CP(wr_clk), .CDN(n53), .Q(
        n119) );
  EDFCNQD1 clk0_r_REG339_S1 ( .D(in[2]), .E(n55), .CP(wr_clk), .CDN(n53), .Q(
        n117) );
  EDFCNQD1 clk0_r_REG341_S1 ( .D(in[2]), .E(n22), .CP(wr_clk), .CDN(n3), .Q(
        n115) );
  EDFCNQD1 clk0_r_REG343_S1 ( .D(in[2]), .E(N37), .CP(wr_clk), .CDN(n3), .Q(
        n113) );
  EDFCNQD1 clk0_r_REG345_S1 ( .D(in[2]), .E(n19), .CP(wr_clk), .CDN(n3), .Q(
        n111) );
  EDFCNQD1 clk0_r_REG347_S1 ( .D(in[2]), .E(net34680), .CP(wr_clk), .CDN(n5), 
        .Q(n109) );
  EDFCNQD1 clk0_r_REG349_S1 ( .D(in[2]), .E(net33754), .CP(wr_clk), .CDN(n5), 
        .Q(n107) );
  EDFCNQD1 clk0_r_REG351_S1 ( .D(in[2]), .E(net34726), .CP(wr_clk), .CDN(n3), 
        .Q(n105) );
  EDFCNQD1 clk0_r_REG353_S1 ( .D(in[1]), .E(n36), .CP(wr_clk), .CDN(n3), .Q(
        n103) );
  EDFCNQD1 clk0_r_REG355_S1 ( .D(in[1]), .E(n55), .CP(wr_clk), .CDN(n3), .Q(
        n101) );
  EDFCNQD1 clk0_r_REG357_S1 ( .D(in[1]), .E(n22), .CP(wr_clk), .CDN(n3), .Q(
        n99) );
  EDFCNQD1 clk0_r_REG359_S1 ( .D(in[1]), .E(N37), .CP(wr_clk), .CDN(n3), .Q(
        n97) );
  EDFCNQD1 clk0_r_REG361_S1 ( .D(in[1]), .E(n19), .CP(wr_clk), .CDN(n5), .Q(
        n95) );
  EDFCNQD1 clk0_r_REG363_S1 ( .D(in[1]), .E(net34680), .CP(wr_clk), .CDN(n5), 
        .Q(n93) );
  EDFCNQD1 clk0_r_REG365_S1 ( .D(in[1]), .E(net33754), .CP(wr_clk), .CDN(n5), 
        .Q(n91) );
  EDFCNQD1 clk0_r_REG367_S1 ( .D(in[1]), .E(net34726), .CP(wr_clk), .CDN(n3), 
        .Q(n89) );
  EDFCNQD1 clk0_r_REG369_S1 ( .D(in[0]), .E(n36), .CP(wr_clk), .CDN(n3), .Q(
        n87) );
  EDFCNQD1 clk0_r_REG371_S1 ( .D(in[0]), .E(n55), .CP(wr_clk), .CDN(n3), .Q(
        n85) );
  EDFCNQD1 clk0_r_REG373_S1 ( .D(in[0]), .E(n22), .CP(wr_clk), .CDN(n3), .Q(
        n83) );
  EDFCNQD1 clk0_r_REG375_S1 ( .D(in[0]), .E(N37), .CP(wr_clk), .CDN(n5), .Q(
        n81) );
  EDFCNQD1 clk0_r_REG377_S1 ( .D(in[0]), .E(n19), .CP(wr_clk), .CDN(n3), .Q(
        n79) );
  EDFCNQD1 clk0_r_REG379_S1 ( .D(in[0]), .E(net34680), .CP(wr_clk), .CDN(n53), 
        .Q(n77) );
  EDFCNQD1 clk0_r_REG381_S1 ( .D(in[0]), .E(net33754), .CP(wr_clk), .CDN(n43), 
        .Q(n75) );
  EDFCNQD1 clk0_r_REG383_S1 ( .D(in[0]), .E(net34726), .CP(wr_clk), .CDN(n3), 
        .Q(n73) );
  EDFCNQD2 clk1_r_REG395_S1 ( .D(rd_ptr_bin[3]), .E(rd_fire), .CP(rd_clk), 
        .CDN(n3), .Q(n469) );
  EDFCNQD1 clk0_r_REG356_S1 ( .D(in[1]), .E(N40), .CP(wr_clk), .CDN(n3), .Q(
        n100) );
  EDFCNQD1 clk1_r_REG397_S1 ( .D(rd_ptr_bin[2]), .E(rd_fire), .CP(rd_clk), 
        .CDN(n3), .Q(n467) );
  EDFCNQD1 clk1_r_REG394_S1 ( .D(rd_ptr_gray[4]), .E(rd_fire), .CP(rd_clk), 
        .CDN(n43), .Q(rd_ptr_gray_sync_wr1_4_) );
  EDFCNQD2 clk0_r_REG31_S1 ( .D(in[22]), .E(net34726), .CP(wr_clk), .CDN(n3), 
        .Q(n425) );
  EDFCNQD2 clk0_r_REG79_S1 ( .D(in[19]), .E(net34726), .CP(wr_clk), .CDN(n3), 
        .Q(n377) );
  EDFCNQD2 clk0_r_REG27_S1 ( .D(in[22]), .E(net34680), .CP(wr_clk), .CDN(n3), 
        .Q(n429) );
  EDFCNQD1 clk0_r_REG308_S1 ( .D(in[4]), .E(n18), .CP(wr_clk), .CDN(n52), .Q(
        n148) );
  EDFCNQD2 clk0_r_REG276_S1 ( .D(in[6]), .E(n17), .CP(wr_clk), .CDN(n3), .Q(
        n180) );
  EDFCNQD2 clk0_r_REG180_S1 ( .D(in[12]), .E(n17), .CP(wr_clk), .CDN(n3), .Q(
        n276) );
  EDFCNQD2 clk0_r_REG372_S1 ( .D(in[0]), .E(n18), .CP(wr_clk), .CDN(n3), .Q(
        n84) );
  EDFCNQD2 clk0_r_REG340_S1 ( .D(in[2]), .E(n17), .CP(wr_clk), .CDN(n3), .Q(
        n116) );
  EDFCNQD2 clk0_r_REG4_S1 ( .D(in[23]), .E(n18), .CP(wr_clk), .CDN(n3), .Q(
        n452) );
  EDFCNQD2 clk0_r_REG292_S1 ( .D(in[5]), .E(n17), .CP(wr_clk), .CDN(n3), .Q(
        n164) );
  EDFCND1 clk0_r_REG411_S1 ( .D(wr_ptr_bin[1]), .E(n4), .CP(wr_clk), .CDN(n5), 
        .Q(net34874), .QN(net34873) );
  EDFCND1 clk0_r_REG412_S1 ( .D(wr_ptr_bin[0]), .E(n4), .CP(wr_clk), .CDN(n5), 
        .Q(net34902), .QN(n11) );
  EDFCNQD1 clk0_r_REG409_S1 ( .D(net35113), .E(n4), .CP(wr_clk), .CDN(n53), 
        .Q(net31638) );
  EDFCNQD1 clk0_r_REG408_S1 ( .D(net35118), .E(n4), .CP(wr_clk), .CDN(n5), .Q(
        n60) );
  DFCNQD1 clk0_r_REG397_S1 ( .D(n61), .CP(wr_clk), .CDN(n3), .Q(net31624) );
  EDFCNQD1 clk0_r_REG164_S1 ( .D(in[13]), .E(n18), .CP(wr_clk), .CDN(n5), .Q(
        n292) );
  EDFCNQD1 clk0_r_REG15_S1 ( .D(in[23]), .E(net34726), .CP(wr_clk), .CDN(n52), 
        .Q(n441) );
  EDFCNQD1 clk0_r_REG68_S1 ( .D(in[19]), .E(n17), .CP(wr_clk), .CDN(n53), .Q(
        n388) );
  EDFCNQD1 clk0_r_REG11_S1 ( .D(in[23]), .E(net34680), .CP(wr_clk), .CDN(n3), 
        .Q(n445) );
  EDFCNQD1 clk0_r_REG393_S1 ( .D(wr_ptr_gray_next[1]), .E(n4), .CP(wr_clk), 
        .CDN(n5), .Q(n64) );
  CKBD4 U3 ( .I(n37), .Z(n54) );
  NR2XD1 U4 ( .A1(net34702), .A2(net34698), .ZN(n18) );
  BUFFD6 U5 ( .I(n35), .Z(n55) );
  NR3D4 U6 ( .A1(net34824), .A2(net34682), .A3(net34873), .ZN(net34680) );
  NR2XD0 U7 ( .A1(net34686), .A2(net34698), .ZN(n26) );
  CKND2D4 U8 ( .A1(n7), .A2(net34873), .ZN(net34688) );
  CKND2D1 U9 ( .A1(net34693), .A2(net31639), .ZN(net34682) );
  CKND2D2 U10 ( .A1(n7), .A2(n9), .ZN(net34822) );
  INVD1 U11 ( .I(net34873), .ZN(n9) );
  CKND2D1 U12 ( .A1(net34692), .A2(net31638), .ZN(net34698) );
  BUFFD1 U13 ( .I(net34902), .Z(n8) );
  CKND2D1 U14 ( .A1(net34722), .A2(net34723), .ZN(net34830) );
  INVD0 U15 ( .I(n66), .ZN(n24) );
  CKND2D0 U16 ( .A1(net31638), .A2(net31639), .ZN(n16) );
  AN2D4 U17 ( .A1(net34716), .A2(net34717), .Z(n2) );
  NR2XD3 U18 ( .A1(net34688), .A2(n16), .ZN(net33754) );
  CKBD6 U19 ( .I(n43), .Z(n3) );
  BUFFD6 U20 ( .I(net34704), .Z(net34860) );
  BUFFD6 U21 ( .I(n26), .Z(n23) );
  NR2D3 U22 ( .A1(net34702), .A2(net34698), .ZN(n17) );
  CKND2 U23 ( .I(n20), .ZN(n4) );
  BUFFD3 U24 ( .I(n576), .Z(o_empty) );
  CKXOR2D1 U25 ( .A1(n70), .A2(wr_ptr_gray_next[0]), .Z(n40) );
  ND2D1 U26 ( .A1(net34692), .A2(net34693), .ZN(n44) );
  INVD1 U27 ( .I(n467), .ZN(n27) );
  INVD1 U28 ( .I(net31619), .ZN(n14) );
  INVD6 U29 ( .I(n32), .ZN(N37) );
  IND2D2 U30 ( .A1(net34822), .B1(net34697), .ZN(n32) );
  NR2XD3 U31 ( .A1(net34822), .A2(n16), .ZN(net34726) );
  CKXOR2D0 U32 ( .A1(net35118), .A2(net35113), .Z(wr_ptr_gray_next[3]) );
  ND2D1 U33 ( .A1(n25), .A2(net34713), .ZN(n38) );
  CKBD2 U34 ( .I(n43), .Z(n5) );
  NR2D2 U35 ( .A1(net34686), .A2(n16), .ZN(net34704) );
  INVD4 U36 ( .I(n42), .ZN(n6) );
  CKND4 U37 ( .I(net34727), .ZN(n7) );
  INVD1 U38 ( .I(net34682), .ZN(net34717) );
  CKND2D1 U39 ( .A1(n11), .A2(net34873), .ZN(n10) );
  INVD1 U40 ( .I(net31639), .ZN(net34692) );
  INVD1 U41 ( .I(net31638), .ZN(net34693) );
  NR2XD1 U42 ( .A1(net34702), .A2(net34698), .ZN(N40) );
  AN2D2 U43 ( .A1(n7), .A2(n12), .Z(n35) );
  NR2D2 U44 ( .A1(n20), .A2(n8), .ZN(net34709) );
  OR2D4 U45 ( .A1(n20), .A2(n10), .Z(net34702) );
  NR2D0 U46 ( .A1(net34873), .A2(n44), .ZN(n12) );
  INVD0 U47 ( .I(n469), .ZN(n33) );
  INVD1 U48 ( .I(n465), .ZN(n41) );
  INR2D1 U49 ( .A1(rd), .B1(o_empty), .ZN(rd_fire) );
  XNR2D0 U50 ( .A1(wr_ptr_bin[1]), .A2(net34902), .ZN(wr_ptr_gray_next[0]) );
  CKXOR2D0 U51 ( .A1(net35113), .A2(wr_ptr_bin[2]), .Z(n56) );
  INVD0 U52 ( .I(wr), .ZN(n15) );
  OAI221D0 U53 ( .A1(n470), .A2(rd_ptr_gray[1]), .B1(n471), .B2(rd_ptr_gray[2]), .C(n28), .ZN(n29) );
  AOI22D0 U54 ( .A1(rd_ptr_gray[1]), .A2(n470), .B1(rd_ptr_gray[2]), .B2(n471), 
        .ZN(n28) );
  AOI22D0 U55 ( .A1(rd_ptr_gray[3]), .A2(n472), .B1(rd_ptr_gray_sync_wr1_4_), 
        .B2(n473), .ZN(n34) );
  INVD0 U56 ( .I(rd_ptr_gray[0]), .ZN(n48) );
  ND2D1 U57 ( .A1(net34830), .A2(net34831), .ZN(n39) );
  INVD1 U58 ( .I(wr_ptr_bin_next[4]), .ZN(net34723) );
  INVD0 U59 ( .I(net34723), .ZN(net35118) );
  ND2D1 U60 ( .A1(n13), .A2(net31624), .ZN(net34722) );
  OAI21D1 U62 ( .A1(n13), .A2(net31624), .B(wr_ptr_bin_next[4]), .ZN(net34831)
         );
  XNR2D1 U63 ( .A1(wr_ptr_bin_next[3]), .A2(n14), .ZN(n13) );
  XNR2D1 U64 ( .A1(net34714), .A2(wr_ptr_bin_next[3]), .ZN(net34713) );
  INVD0 U65 ( .I(wr_ptr_bin_next[3]), .ZN(net35112) );
  ND2D2 U66 ( .A1(net34709), .A2(n9), .ZN(net34686) );
  INVD2 U67 ( .I(net34718), .ZN(n20) );
  NR2XD1 U68 ( .A1(n1), .A2(n15), .ZN(net34718) );
  CKND2D2 U69 ( .A1(net34718), .A2(n8), .ZN(net34727) );
  NR2XD3 U70 ( .A1(net34702), .A2(n16), .ZN(net34914) );
  INVD0 U72 ( .I(net35112), .ZN(net35113) );
  INVD0 U73 ( .I(n4), .ZN(net34940) );
  NR2XD3 U74 ( .A1(net34688), .A2(net34682), .ZN(n19) );
  NR2XD3 U75 ( .A1(net34702), .A2(net34682), .ZN(n21) );
  NR2XD3 U76 ( .A1(net34688), .A2(net34698), .ZN(n22) );
  INVD1 U77 ( .I(N48), .ZN(n42) );
  NR2XD3 U78 ( .A1(net34688), .A2(n44), .ZN(n36) );
  INVD2 U79 ( .I(n7), .ZN(net34824) );
  NR2D2 U80 ( .A1(net34686), .A2(n44), .ZN(n37) );
  INVD0 U81 ( .I(rd_ptr_bin[1]), .ZN(n45) );
  TIEL U82 ( .ZN(n474) );
  CKXOR2D1 U83 ( .A1(wr_ptr_bin[2]), .A2(wr_ptr_bin[1]), .Z(
        wr_ptr_gray_next[1]) );
  CKND2 U84 ( .I(net34686), .ZN(net34716) );
  XNR2D1 U85 ( .A1(wr_ptr_gray_next[1]), .A2(n68), .ZN(n25) );
  XNR2D1 U86 ( .A1(wr_ptr_bin[2]), .A2(n24), .ZN(net34714) );
  MUX2ND0 U88 ( .I0(n466), .I1(n27), .S(n41), .ZN(rd_ptr_gray[1]) );
  MUX2ND0 U89 ( .I0(n468), .I1(n33), .S(n27), .ZN(rd_ptr_gray[2]) );
  INVD1 U90 ( .I(net34698), .ZN(net34697) );
  MUX2ND0 U91 ( .I0(n33), .I1(n468), .S(rd_ptr_gray_sync_wr1_4_), .ZN(
        rd_ptr_gray[3]) );
  OAI221D0 U92 ( .A1(n472), .A2(rd_ptr_gray[3]), .B1(n473), .B2(
        rd_ptr_gray_sync_wr1_4_), .C(n34), .ZN(n30) );
  INVD0 U93 ( .I(n459), .ZN(n573) );
  INVD0 U94 ( .I(n461), .ZN(n575) );
  INVD0 U95 ( .I(n460), .ZN(n572) );
  INVD0 U96 ( .I(n462), .ZN(n574) );
  MUX2ND0 U97 ( .I0(n41), .I1(n464), .S(n463), .ZN(rd_ptr_gray[0]) );
  INVD0 U98 ( .I(reset), .ZN(n43) );
  CKBD1 U99 ( .I(n43), .Z(n53) );
  INVD0 U100 ( .I(reset), .ZN(n52) );
  NR3D0 U101 ( .A1(n44), .A2(n8), .A3(net34874), .ZN(N17) );
  MUX2ND0 U102 ( .I0(n50), .I1(n45), .S(rd_fire), .ZN(n57) );
  INVD0 U103 ( .I(rd_ptr_bin[2]), .ZN(n46) );
  MUX2ND0 U104 ( .I0(n51), .I1(n46), .S(rd_fire), .ZN(n58) );
  INVD0 U105 ( .I(rd_ptr_bin[3]), .ZN(n47) );
  MUX2ND0 U106 ( .I0(n49), .I1(n47), .S(rd_fire), .ZN(n59) );
  MUX2ND0 U107 ( .I0(n48), .I1(rd_ptr_gray[0]), .S(n457), .ZN(n31) );
  MUX4ND0 U108 ( .I0(n88), .I1(n87), .I2(n86), .I3(n85), .S0(n463), .S1(n465), 
        .ZN(n476) );
  MUX4ND0 U109 ( .I0(n84), .I1(n83), .I2(n82), .I3(n81), .S0(n463), .S1(n465), 
        .ZN(n477) );
  MUX4ND0 U110 ( .I0(n80), .I1(n79), .I2(n78), .I3(n77), .S0(n463), .S1(n465), 
        .ZN(n478) );
  MUX4ND0 U111 ( .I0(n76), .I1(n75), .I2(n74), .I3(n73), .S0(n463), .S1(n465), 
        .ZN(n479) );
  MUX4ND0 U112 ( .I0(n476), .I1(n477), .I2(n478), .I3(n479), .S0(n469), .S1(
        n467), .ZN(out[0]) );
  MUX4ND0 U113 ( .I0(n104), .I1(n103), .I2(n102), .I3(n101), .S0(n463), .S1(
        n465), .ZN(n480) );
  MUX4ND0 U114 ( .I0(n100), .I1(n99), .I2(n98), .I3(n97), .S0(n463), .S1(n465), 
        .ZN(n481) );
  MUX4ND0 U115 ( .I0(n96), .I1(n95), .I2(n94), .I3(n93), .S0(n463), .S1(n465), 
        .ZN(n482) );
  MUX4ND0 U116 ( .I0(n92), .I1(n91), .I2(n90), .I3(n89), .S0(n463), .S1(n465), 
        .ZN(n483) );
  MUX4ND0 U117 ( .I0(n480), .I1(n481), .I2(n482), .I3(n483), .S0(n469), .S1(
        n467), .ZN(out[1]) );
  MUX4ND0 U118 ( .I0(n120), .I1(n119), .I2(n118), .I3(n117), .S0(n463), .S1(
        n465), .ZN(n484) );
  MUX4ND0 U119 ( .I0(n116), .I1(n115), .I2(n114), .I3(n113), .S0(n463), .S1(
        n465), .ZN(n485) );
  MUX4ND0 U120 ( .I0(n112), .I1(n111), .I2(n110), .I3(n109), .S0(n463), .S1(
        n465), .ZN(n486) );
  MUX4ND0 U121 ( .I0(n108), .I1(n107), .I2(n106), .I3(n105), .S0(n463), .S1(
        n465), .ZN(n487) );
  MUX4ND0 U122 ( .I0(n484), .I1(n485), .I2(n486), .I3(n487), .S0(n469), .S1(
        n467), .ZN(out[2]) );
  MUX4ND0 U123 ( .I0(n136), .I1(n135), .I2(n134), .I3(n133), .S0(n463), .S1(
        n465), .ZN(n488) );
  MUX4ND0 U124 ( .I0(n132), .I1(n131), .I2(n130), .I3(n129), .S0(n463), .S1(
        n465), .ZN(n489) );
  MUX4ND0 U125 ( .I0(n128), .I1(n127), .I2(n126), .I3(n125), .S0(n463), .S1(
        n465), .ZN(n490) );
  MUX4ND0 U126 ( .I0(n124), .I1(n123), .I2(n122), .I3(n121), .S0(n463), .S1(
        n465), .ZN(n491) );
  MUX4ND0 U127 ( .I0(n488), .I1(n489), .I2(n490), .I3(n491), .S0(n469), .S1(
        n467), .ZN(out[3]) );
  MUX4ND0 U128 ( .I0(n152), .I1(n151), .I2(n150), .I3(n149), .S0(n463), .S1(
        n465), .ZN(n492) );
  MUX4ND0 U129 ( .I0(n148), .I1(n147), .I2(n146), .I3(n145), .S0(n463), .S1(
        n465), .ZN(n493) );
  MUX4ND0 U130 ( .I0(n144), .I1(n143), .I2(n142), .I3(n141), .S0(n463), .S1(
        n465), .ZN(n494) );
  MUX4ND0 U131 ( .I0(n140), .I1(n139), .I2(n138), .I3(n137), .S0(n463), .S1(
        n465), .ZN(n495) );
  MUX4ND0 U132 ( .I0(n492), .I1(n493), .I2(n494), .I3(n495), .S0(n469), .S1(
        n467), .ZN(out[4]) );
  MUX4ND0 U133 ( .I0(n168), .I1(n167), .I2(n166), .I3(n165), .S0(n463), .S1(
        n465), .ZN(n496) );
  MUX4ND0 U134 ( .I0(n164), .I1(n163), .I2(n162), .I3(n161), .S0(n463), .S1(
        n465), .ZN(n497) );
  MUX4ND0 U135 ( .I0(n160), .I1(n159), .I2(n158), .I3(n157), .S0(n463), .S1(
        n465), .ZN(n498) );
  MUX4ND0 U136 ( .I0(n156), .I1(n155), .I2(n154), .I3(n153), .S0(n463), .S1(
        n465), .ZN(n499) );
  MUX4ND0 U137 ( .I0(n496), .I1(n497), .I2(n498), .I3(n499), .S0(n469), .S1(
        n467), .ZN(out[5]) );
  MUX4ND0 U138 ( .I0(n184), .I1(n183), .I2(n182), .I3(n181), .S0(n463), .S1(
        n465), .ZN(n500) );
  MUX4ND0 U139 ( .I0(n180), .I1(n179), .I2(n178), .I3(n177), .S0(n463), .S1(
        n465), .ZN(n501) );
  MUX4ND0 U140 ( .I0(n176), .I1(n175), .I2(n174), .I3(n173), .S0(n463), .S1(
        n465), .ZN(n502) );
  MUX4ND0 U141 ( .I0(n172), .I1(n171), .I2(n170), .I3(n169), .S0(n463), .S1(
        n465), .ZN(n503) );
  MUX4ND0 U142 ( .I0(n500), .I1(n501), .I2(n502), .I3(n503), .S0(n469), .S1(
        n467), .ZN(out[6]) );
  MUX4ND0 U143 ( .I0(n200), .I1(n199), .I2(n198), .I3(n197), .S0(n463), .S1(
        n465), .ZN(n504) );
  MUX4ND0 U144 ( .I0(n196), .I1(n195), .I2(n194), .I3(n193), .S0(n463), .S1(
        n465), .ZN(n505) );
  MUX4ND0 U145 ( .I0(n192), .I1(n191), .I2(n190), .I3(n189), .S0(n463), .S1(
        n465), .ZN(n506) );
  MUX4ND0 U146 ( .I0(n188), .I1(n187), .I2(n186), .I3(n185), .S0(n463), .S1(
        n465), .ZN(n507) );
  MUX4ND0 U147 ( .I0(n504), .I1(n505), .I2(n506), .I3(n507), .S0(n469), .S1(
        n467), .ZN(out[7]) );
  MUX4ND0 U148 ( .I0(n216), .I1(n215), .I2(n214), .I3(n213), .S0(n463), .S1(
        n465), .ZN(n508) );
  MUX4ND0 U149 ( .I0(n212), .I1(n211), .I2(n210), .I3(n209), .S0(n463), .S1(
        n465), .ZN(n509) );
  MUX4ND0 U150 ( .I0(n208), .I1(n207), .I2(n206), .I3(n205), .S0(n463), .S1(
        n465), .ZN(n510) );
  MUX4ND0 U151 ( .I0(n204), .I1(n203), .I2(n202), .I3(n201), .S0(n463), .S1(
        n465), .ZN(n511) );
  MUX4ND0 U152 ( .I0(n508), .I1(n509), .I2(n510), .I3(n511), .S0(n469), .S1(
        n467), .ZN(out[8]) );
  MUX4ND0 U153 ( .I0(n232), .I1(n231), .I2(n230), .I3(n229), .S0(n463), .S1(
        n465), .ZN(n512) );
  MUX4ND0 U154 ( .I0(n228), .I1(n227), .I2(n226), .I3(n225), .S0(n463), .S1(
        n465), .ZN(n513) );
  MUX4ND0 U155 ( .I0(n224), .I1(n223), .I2(n222), .I3(n221), .S0(n463), .S1(
        n465), .ZN(n514) );
  MUX4ND0 U156 ( .I0(n220), .I1(n219), .I2(n218), .I3(n217), .S0(n463), .S1(
        n465), .ZN(n515) );
  MUX4ND0 U157 ( .I0(n512), .I1(n513), .I2(n514), .I3(n515), .S0(n469), .S1(
        n467), .ZN(out[9]) );
  MUX4ND0 U158 ( .I0(n248), .I1(n247), .I2(n246), .I3(n245), .S0(n463), .S1(
        n465), .ZN(n516) );
  MUX4ND0 U159 ( .I0(n244), .I1(n243), .I2(n242), .I3(n241), .S0(n463), .S1(
        n465), .ZN(n517) );
  MUX4ND0 U160 ( .I0(n240), .I1(n239), .I2(n238), .I3(n237), .S0(n463), .S1(
        n465), .ZN(n518) );
  MUX4ND0 U161 ( .I0(n236), .I1(n235), .I2(n234), .I3(n233), .S0(n463), .S1(
        n465), .ZN(n519) );
  MUX4ND0 U162 ( .I0(n516), .I1(n517), .I2(n518), .I3(n519), .S0(n469), .S1(
        n467), .ZN(out[10]) );
  MUX4ND0 U163 ( .I0(n264), .I1(n263), .I2(n262), .I3(n261), .S0(n463), .S1(
        n465), .ZN(n520) );
  MUX4ND0 U164 ( .I0(n260), .I1(n259), .I2(n258), .I3(n257), .S0(n463), .S1(
        n465), .ZN(n521) );
  MUX4ND0 U165 ( .I0(n256), .I1(n255), .I2(n254), .I3(n253), .S0(n463), .S1(
        n465), .ZN(n522) );
  MUX4ND0 U166 ( .I0(n252), .I1(n251), .I2(n250), .I3(n249), .S0(n463), .S1(
        n465), .ZN(n523) );
  MUX4ND0 U167 ( .I0(n520), .I1(n521), .I2(n522), .I3(n523), .S0(n469), .S1(
        n467), .ZN(out[11]) );
  MUX4ND0 U168 ( .I0(n280), .I1(n279), .I2(n278), .I3(n277), .S0(n463), .S1(
        n465), .ZN(n524) );
  MUX4ND0 U169 ( .I0(n276), .I1(n275), .I2(n274), .I3(n273), .S0(n463), .S1(
        n465), .ZN(n525) );
  MUX4ND0 U170 ( .I0(n272), .I1(n271), .I2(n270), .I3(n269), .S0(n463), .S1(
        n465), .ZN(n526) );
  MUX4ND0 U171 ( .I0(n268), .I1(n267), .I2(n266), .I3(n265), .S0(n463), .S1(
        n465), .ZN(n527) );
  MUX4ND0 U172 ( .I0(n524), .I1(n525), .I2(n526), .I3(n527), .S0(n469), .S1(
        n467), .ZN(out[12]) );
  MUX4ND0 U173 ( .I0(n296), .I1(n295), .I2(n294), .I3(n293), .S0(n463), .S1(
        n465), .ZN(n528) );
  MUX4ND0 U174 ( .I0(n292), .I1(n291), .I2(n290), .I3(n289), .S0(n463), .S1(
        n465), .ZN(n529) );
  MUX4ND0 U175 ( .I0(n288), .I1(n287), .I2(n286), .I3(n285), .S0(n463), .S1(
        n465), .ZN(n530) );
  MUX4ND0 U176 ( .I0(n284), .I1(n283), .I2(n282), .I3(n281), .S0(n463), .S1(
        n465), .ZN(n531) );
  MUX4ND0 U177 ( .I0(n528), .I1(n529), .I2(n530), .I3(n531), .S0(n469), .S1(
        n467), .ZN(out[13]) );
  MUX4ND0 U178 ( .I0(n312), .I1(n311), .I2(n310), .I3(n309), .S0(n463), .S1(
        n465), .ZN(n532) );
  MUX4ND0 U179 ( .I0(n308), .I1(n307), .I2(n306), .I3(n305), .S0(n463), .S1(
        n465), .ZN(n533) );
  MUX4ND0 U180 ( .I0(n304), .I1(n303), .I2(n302), .I3(n301), .S0(n463), .S1(
        n465), .ZN(n534) );
  MUX4ND0 U181 ( .I0(n300), .I1(n299), .I2(n298), .I3(n297), .S0(n463), .S1(
        n465), .ZN(n535) );
  MUX4ND0 U182 ( .I0(n532), .I1(n533), .I2(n534), .I3(n535), .S0(n469), .S1(
        n467), .ZN(out[14]) );
  MUX4ND0 U183 ( .I0(n328), .I1(n327), .I2(n326), .I3(n325), .S0(n463), .S1(
        n465), .ZN(n536) );
  MUX4ND0 U184 ( .I0(n324), .I1(n323), .I2(n322), .I3(n321), .S0(n463), .S1(
        n465), .ZN(n537) );
  MUX4ND0 U185 ( .I0(n320), .I1(n319), .I2(n318), .I3(n317), .S0(n463), .S1(
        n465), .ZN(n538) );
  MUX4ND0 U186 ( .I0(n316), .I1(n315), .I2(n314), .I3(n313), .S0(n463), .S1(
        n465), .ZN(n539) );
  MUX4ND0 U187 ( .I0(n536), .I1(n537), .I2(n538), .I3(n539), .S0(n469), .S1(
        n467), .ZN(out[15]) );
  MUX4ND0 U188 ( .I0(n344), .I1(n343), .I2(n342), .I3(n341), .S0(n463), .S1(
        n465), .ZN(n540) );
  MUX4ND0 U189 ( .I0(n340), .I1(n339), .I2(n338), .I3(n337), .S0(n463), .S1(
        n465), .ZN(n541) );
  MUX4ND0 U190 ( .I0(n336), .I1(n335), .I2(n334), .I3(n333), .S0(n463), .S1(
        n465), .ZN(n542) );
  MUX4ND0 U191 ( .I0(n332), .I1(n331), .I2(n330), .I3(n329), .S0(n463), .S1(
        n465), .ZN(n543) );
  MUX4ND0 U192 ( .I0(n540), .I1(n541), .I2(n542), .I3(n543), .S0(n469), .S1(
        n467), .ZN(out[16]) );
  MUX4ND0 U193 ( .I0(n360), .I1(n359), .I2(n358), .I3(n357), .S0(n463), .S1(
        n465), .ZN(n544) );
  MUX4ND0 U194 ( .I0(n356), .I1(n355), .I2(n354), .I3(n353), .S0(n463), .S1(
        n465), .ZN(n545) );
  MUX4ND0 U195 ( .I0(n352), .I1(n351), .I2(n350), .I3(n349), .S0(n463), .S1(
        n465), .ZN(n546) );
  MUX4ND0 U196 ( .I0(n348), .I1(n347), .I2(n346), .I3(n345), .S0(n463), .S1(
        n465), .ZN(n547) );
  MUX4ND0 U197 ( .I0(n544), .I1(n545), .I2(n546), .I3(n547), .S0(n469), .S1(
        n467), .ZN(out[17]) );
  MUX4ND0 U198 ( .I0(n376), .I1(n375), .I2(n374), .I3(n373), .S0(n463), .S1(
        n465), .ZN(n548) );
  MUX4ND0 U199 ( .I0(n372), .I1(n371), .I2(n370), .I3(n369), .S0(n463), .S1(
        n465), .ZN(n549) );
  MUX4ND0 U200 ( .I0(n368), .I1(n367), .I2(n366), .I3(n365), .S0(n463), .S1(
        n465), .ZN(n550) );
  MUX4ND0 U201 ( .I0(n364), .I1(n363), .I2(n362), .I3(n361), .S0(n463), .S1(
        n465), .ZN(n551) );
  MUX4ND0 U202 ( .I0(n548), .I1(n549), .I2(n550), .I3(n551), .S0(n469), .S1(
        n467), .ZN(out[18]) );
  MUX4ND0 U203 ( .I0(n392), .I1(n391), .I2(n390), .I3(n389), .S0(n463), .S1(
        n465), .ZN(n552) );
  MUX4ND0 U204 ( .I0(n388), .I1(n387), .I2(n386), .I3(n385), .S0(n463), .S1(
        n465), .ZN(n553) );
  MUX4ND0 U205 ( .I0(n384), .I1(n383), .I2(n382), .I3(n381), .S0(n463), .S1(
        n465), .ZN(n554) );
  MUX4ND0 U206 ( .I0(n380), .I1(n379), .I2(n378), .I3(n377), .S0(n463), .S1(
        n465), .ZN(n555) );
  MUX4ND0 U207 ( .I0(n552), .I1(n553), .I2(n554), .I3(n555), .S0(n469), .S1(
        n467), .ZN(out[19]) );
  MUX4ND0 U208 ( .I0(n408), .I1(n407), .I2(n406), .I3(n405), .S0(n463), .S1(
        n465), .ZN(n556) );
  MUX4ND0 U209 ( .I0(n404), .I1(n403), .I2(n402), .I3(n401), .S0(n463), .S1(
        n465), .ZN(n557) );
  MUX4ND0 U210 ( .I0(n400), .I1(n399), .I2(n398), .I3(n397), .S0(n463), .S1(
        n465), .ZN(n558) );
  MUX4ND0 U211 ( .I0(n396), .I1(n395), .I2(n394), .I3(n393), .S0(n463), .S1(
        n465), .ZN(n559) );
  MUX4ND0 U212 ( .I0(n556), .I1(n557), .I2(n558), .I3(n559), .S0(n469), .S1(
        n467), .ZN(out[20]) );
  MUX4ND0 U213 ( .I0(n424), .I1(n423), .I2(n422), .I3(n421), .S0(n463), .S1(
        n465), .ZN(n560) );
  MUX4ND0 U214 ( .I0(n420), .I1(n419), .I2(n418), .I3(n417), .S0(n463), .S1(
        n465), .ZN(n561) );
  MUX4ND0 U215 ( .I0(n416), .I1(n415), .I2(n414), .I3(n413), .S0(n463), .S1(
        n465), .ZN(n562) );
  MUX4ND0 U216 ( .I0(n412), .I1(n411), .I2(n410), .I3(n409), .S0(n463), .S1(
        n465), .ZN(n563) );
  MUX4ND0 U217 ( .I0(n560), .I1(n561), .I2(n562), .I3(n563), .S0(n469), .S1(
        n467), .ZN(out[21]) );
  MUX4ND0 U218 ( .I0(n440), .I1(n439), .I2(n438), .I3(n437), .S0(n463), .S1(
        n465), .ZN(n564) );
  MUX4ND0 U219 ( .I0(n436), .I1(n435), .I2(n434), .I3(n433), .S0(n463), .S1(
        n465), .ZN(n565) );
  MUX4ND0 U220 ( .I0(n432), .I1(n431), .I2(n430), .I3(n429), .S0(n463), .S1(
        n465), .ZN(n566) );
  MUX4ND0 U221 ( .I0(n428), .I1(n427), .I2(n426), .I3(n425), .S0(n463), .S1(
        n465), .ZN(n567) );
  MUX4ND0 U222 ( .I0(n564), .I1(n565), .I2(n566), .I3(n567), .S0(n469), .S1(
        n467), .ZN(out[22]) );
  MUX4ND0 U223 ( .I0(n456), .I1(n455), .I2(n454), .I3(n453), .S0(n463), .S1(
        n465), .ZN(n568) );
  MUX4ND0 U224 ( .I0(n452), .I1(n451), .I2(n450), .I3(n449), .S0(n463), .S1(
        n465), .ZN(n569) );
  MUX4ND0 U225 ( .I0(n448), .I1(n447), .I2(n446), .I3(n445), .S0(n463), .S1(
        n465), .ZN(n570) );
  MUX4ND0 U226 ( .I0(n444), .I1(n443), .I2(n442), .I3(n441), .S0(n463), .S1(
        n465), .ZN(n571) );
  MUX4ND0 U227 ( .I0(n568), .I1(n569), .I2(n570), .I3(n571), .S0(n469), .S1(
        n467), .ZN(out[23]) );
endmodule


module fifo_depth16_async_bw24_0_DW01_inc_J1_0_0 ( A, SUM );
  input [4:0] A;
  output [4:0] SUM;
  wire   n1, n2, n3;

  HA1D0 U2 ( .A(n2), .B(A[3]), .CO(n1), .S(SUM[3]) );
  HA1D0 U3 ( .A(n3), .B(A[2]), .CO(n2), .S(SUM[2]) );
  HA1D0 U4 ( .A(A[0]), .B(A[1]), .CO(n3), .S(SUM[1]) );
  CKXOR2D0 U8 ( .A1(n1), .A2(A[4]), .Z(SUM[4]) );
  INVD0 U9 ( .I(A[0]), .ZN(SUM[0]) );
endmodule


module fifo_depth16_async_bw24_0_DW01_inc_J1_1_0 ( A, SUM );
  input [4:0] A;
  output [4:0] SUM;
  wire   n1, n2, n3;

  HA1D0 U2 ( .A(n2), .B(A[3]), .CO(n1), .S(SUM[3]) );
  HA1D0 U3 ( .A(n3), .B(A[2]), .CO(n2), .S(SUM[2]) );
  HA1D0 U4 ( .A(A[0]), .B(A[1]), .CO(n3), .S(SUM[1]) );
  CKXOR2D0 U8 ( .A1(n1), .A2(A[4]), .Z(SUM[4]) );
  INVD0 U9 ( .I(A[0]), .ZN(SUM[0]) );
endmodule


module fifo_depth16_async_bw24_3 ( rd_clk, wr_clk, rd, wr, reset, in, out, 
        o_full, o_empty );
  input [23:0] in;
  output [23:0] out;
  input rd_clk, wr_clk, rd, wr, reset;
  output o_full, o_empty;
  wire   n1, n621, rd_fire, wr_ptr_gray_sync_rd1_4_, N17, N48, n2, n3, n4, n6,
         n7, n8, n9, n10, n11, n12, n13, n14, n15, n16, n17, n18, n19, n21,
         n22, n23, n24, n25, n26, n27, n28, n32, n33, n34, n35, n36, n37, n41,
         n42, n43, n44, n45, n46, n47, n48, n49, n50, n51, n52, n53, n54, n55,
         n56, n57, n58, n59, n60, n61, n62, n63, n64, n65, n66, n67, n68, n69,
         n70, n71, n72, n73, n74, n75, n76, n77, n78, n79, n80, n81, n82, n83,
         n84, n85, n86, n87, n88, n89, n90, n91, n92, n93, n94, n95, n96, n97,
         n98, n99, n100, n101, n102, n103, n104, n105, n106, n107, n108, n109,
         n110, n111, n112, n113, n114, n115, n116, n117, n118, n119, n120,
         n121, n122, n123, n124, n125, n126, n127, n128, n129, n130, n131,
         n132, n133, n134, n135, n136, n137, n138, n139, n140, n141, n142,
         n143, n144, n145, n146, n147, n148, n149, n150, n151, n152, n153,
         n154, n155, n156, n157, n158, n159, n160, n161, n162, n163, n164,
         n165, n166, n167, n168, n169, n170, n171, n172, n173, n174, n175,
         n176, n177, n178, n179, n180, n181, n182, n183, n184, n185, n186,
         n187, n188, n189, n190, n191, n192, n193, n194, n195, n196, n197,
         n198, n199, n200, n201, n202, n203, n204, n205, n206, n207, n208,
         n209, n210, n211, n212, n213, n214, n215, n216, n217, n218, n219,
         n220, n221, n222, n223, n224, n225, n226, n227, n228, n229, n230,
         n231, n232, n233, n234, n235, n236, n237, n238, n239, n240, n241,
         n242, n243, n244, n245, n246, n247, n248, n249, n250, n251, n252,
         n253, n254, n255, n256, n257, n258, n259, n260, n261, n262, n263,
         n264, n265, n266, n267, n268, n269, n270, n271, n272, n273, n274,
         n275, n276, n277, n278, n279, n280, n281, n282, n283, n284, n285,
         n286, n287, n288, n289, n290, n291, n292, n293, n294, n295, n296,
         n297, n298, n299, n300, n301, n302, n303, n304, n305, n306, n307,
         n308, n309, n310, n311, n312, n313, n314, n315, n316, n317, n318,
         n319, n320, n321, n322, n323, n324, n325, n326, n327, n328, n329,
         n330, n331, n332, n333, n334, n335, n336, n337, n338, n339, n340,
         n341, n342, n343, n344, n345, n346, n347, n348, n349, n350, n351,
         n352, n353, n354, n355, n356, n357, n358, n359, n360, n361, n362,
         n363, n364, n365, n366, n367, n368, n369, n370, n371, n372, n373,
         n374, n375, n376, n377, n378, n379, n380, n381, n382, n383, n384,
         n385, n386, n387, n388, n389, n390, n391, n392, n393, n394, n395,
         n396, n397, n398, n399, n400, n401, n402, n403, n404, n405, n406,
         n407, n408, n409, n410, n411, n412, n413, n414, n415, n416, n417,
         n418, n419, n420, n421, n422, n423, n424, n425, n426, n427, n428,
         n429, n430, n431, n432, n433, n434, n435, n436, n437, n438, n439,
         n440, n441, n442, n443, n444, n445, n446, n447, n448, n449, n450,
         n451, n452, n453, n454, n455, n456, n457, n458, n459, n460, n461,
         n462, n463, n464, n465, n466, n467, n468, n469, n470, n471, n472,
         n473, n474, n475, n476, n477, n478, n479, n480, n481, n482, n483,
         n484, n485, n486, n487, n488, n489, n490, n491, n492, n493, n494,
         n495, n496, n497, n498, n499, n500, n501, n502, n503, n504, n505,
         n506, n507, n508, n509, n510, n511, n512, n513, n514, n516, n517,
         n518, n519, n520, n521, n522, n523, n524, n525, n526, n527, n528,
         n529, n530, n531, n532, n533, n534, n535, n536, n537, n538, n539,
         n540, n541, n542, n543, n544, n545, n546, n547, n548, n549, n550,
         n551, n552, n553, n554, n555, n556, n557, n558, n559, n560, n561,
         n562, n563, n564, n565, n566, n567, n568, n569, n570, n571, n572,
         n573, n574, n575, n576, n577, n578, n579, n580, n581, n582, n583,
         n584, n585, n586, n587, n588, n589, n590, n591, n592, n593, n594,
         n595, n596, n597, n598, n599, n600, n601, n602, n603, n604, n605,
         n606, n607, n608, n609, n610, n611, n612, n613, n614, n615, n616,
         n617, n618, n619, n620;
  wire   [3:0] rd_ptr_bin;
  wire   [2:0] wr_ptr_bin;
  wire   [4:3] wr_ptr_bin_next;
  wire   [3:0] wr_ptr_gray_next;
  wire   [3:0] wr_ptr_gray_sync_rd2;
  wire   [4:0] rd_ptr_gray;
  tri   rd_clk;
  tri   wr_clk;
  tri   rd;
  tri   wr;
  tri   reset;
  tri   [23:0] in;

  fifo_depth16_async_bw24_0_DW01_inc_J1_0_0 add_x_2 ( .A({
        wr_ptr_gray_sync_rd1_4_, n127, n126, n125, n124}), .SUM({
        wr_ptr_bin_next, wr_ptr_bin}) );
  fifo_depth16_async_bw24_0_DW01_inc_J1_1_0 add_x_1 ( .A({n104, n87, n88, n89, 
        n91}), .SUM({rd_ptr_gray[4], rd_ptr_bin}) );
  NR3D0 U61 ( .A1(n617), .A2(n618), .A3(n619), .ZN(n621) );
  NR3D0 U71 ( .A1(n614), .A2(n615), .A3(n616), .ZN(n1) );
  AO22D0 U87 ( .A1(n79), .A2(N17), .B1(n620), .B2(n514), .Z(N48) );
  EDFCNQD1 clk1_r_REG4_S1 ( .D(in[23]), .E(n8), .CP(wr_clk), .CDN(n4), .Q(n513) );
  EDFCNQD1 clk1_r_REG5_S1 ( .D(in[23]), .E(n6), .CP(wr_clk), .CDN(n4), .Q(n512) );
  EDFCNQD1 clk1_r_REG6_S1 ( .D(in[23]), .E(n86), .CP(wr_clk), .CDN(n4), .Q(
        n511) );
  EDFCNQD1 clk1_r_REG7_S1 ( .D(in[23]), .E(n56), .CP(wr_clk), .CDN(n4), .Q(
        n510) );
  EDFCNQD1 clk1_r_REG8_S1 ( .D(in[23]), .E(n80), .CP(wr_clk), .CDN(n4), .Q(
        n509) );
  EDFCNQD1 clk1_r_REG9_S1 ( .D(in[23]), .E(n12), .CP(wr_clk), .CDN(n115), .Q(
        n508) );
  EDFCNQD1 clk1_r_REG10_S1 ( .D(in[23]), .E(n83), .CP(wr_clk), .CDN(n4), .Q(
        n507) );
  EDFCNQD1 clk1_r_REG11_S1 ( .D(in[23]), .E(n2), .CP(wr_clk), .CDN(n4), .Q(
        n506) );
  EDFCNQD1 clk1_r_REG12_S1 ( .D(in[23]), .E(n10), .CP(wr_clk), .CDN(n115), .Q(
        n505) );
  EDFCNQD1 clk1_r_REG13_S1 ( .D(in[23]), .E(n7), .CP(wr_clk), .CDN(n4), .Q(
        n504) );
  EDFCNQD1 clk1_r_REG14_S1 ( .D(in[23]), .E(n85), .CP(wr_clk), .CDN(n4), .Q(
        n503) );
  EDFCNQD1 clk1_r_REG15_S1 ( .D(in[23]), .E(n3), .CP(wr_clk), .CDN(n4), .Q(
        n502) );
  EDFCNQD1 clk1_r_REG16_S1 ( .D(in[23]), .E(n9), .CP(wr_clk), .CDN(n4), .Q(
        n501) );
  EDFCNQD1 clk1_r_REG17_S1 ( .D(in[23]), .E(n11), .CP(wr_clk), .CDN(n4), .Q(
        n500) );
  EDFCNQD1 clk1_r_REG18_S1 ( .D(in[23]), .E(n84), .CP(wr_clk), .CDN(n4), .Q(
        n499) );
  EDFCNQD1 clk1_r_REG19_S1 ( .D(in[23]), .E(n14), .CP(wr_clk), .CDN(n115), .Q(
        n498) );
  EDFCNQD1 clk1_r_REG20_S1 ( .D(in[22]), .E(n8), .CP(wr_clk), .CDN(n115), .Q(
        n497) );
  EDFCNQD1 clk1_r_REG21_S1 ( .D(in[22]), .E(n6), .CP(wr_clk), .CDN(n4), .Q(
        n496) );
  EDFCNQD1 clk1_r_REG22_S1 ( .D(in[22]), .E(n86), .CP(wr_clk), .CDN(n4), .Q(
        n495) );
  EDFCNQD1 clk1_r_REG23_S1 ( .D(in[22]), .E(n56), .CP(wr_clk), .CDN(n4), .Q(
        n494) );
  EDFCNQD1 clk1_r_REG24_S1 ( .D(in[22]), .E(n13), .CP(wr_clk), .CDN(n115), .Q(
        n493) );
  EDFCNQD1 clk1_r_REG25_S1 ( .D(in[22]), .E(n12), .CP(wr_clk), .CDN(n115), .Q(
        n492) );
  EDFCNQD1 clk1_r_REG26_S1 ( .D(in[22]), .E(n83), .CP(wr_clk), .CDN(n4), .Q(
        n491) );
  EDFCNQD1 clk1_r_REG27_S1 ( .D(in[22]), .E(n2), .CP(wr_clk), .CDN(n4), .Q(
        n490) );
  EDFCNQD1 clk1_r_REG28_S1 ( .D(in[22]), .E(n10), .CP(wr_clk), .CDN(n4), .Q(
        n489) );
  EDFCNQD1 clk1_r_REG29_S1 ( .D(in[22]), .E(n7), .CP(wr_clk), .CDN(n4), .Q(
        n488) );
  EDFCNQD1 clk1_r_REG30_S1 ( .D(in[22]), .E(n85), .CP(wr_clk), .CDN(n4), .Q(
        n487) );
  EDFCNQD1 clk1_r_REG31_S1 ( .D(in[22]), .E(n3), .CP(wr_clk), .CDN(n4), .Q(
        n486) );
  EDFCNQD1 clk1_r_REG32_S1 ( .D(in[22]), .E(n9), .CP(wr_clk), .CDN(n4), .Q(
        n485) );
  EDFCNQD1 clk1_r_REG33_S1 ( .D(in[22]), .E(n11), .CP(wr_clk), .CDN(n4), .Q(
        n484) );
  EDFCNQD1 clk1_r_REG34_S1 ( .D(in[22]), .E(n84), .CP(wr_clk), .CDN(n4), .Q(
        n483) );
  EDFCNQD1 clk1_r_REG35_S1 ( .D(in[22]), .E(n14), .CP(wr_clk), .CDN(n4), .Q(
        n482) );
  EDFCNQD1 clk1_r_REG36_S1 ( .D(in[21]), .E(n8), .CP(wr_clk), .CDN(n115), .Q(
        n481) );
  EDFCNQD1 clk1_r_REG37_S1 ( .D(in[21]), .E(n6), .CP(wr_clk), .CDN(n4), .Q(
        n480) );
  EDFCNQD1 clk1_r_REG38_S1 ( .D(in[21]), .E(n86), .CP(wr_clk), .CDN(n78), .Q(
        n479) );
  EDFCNQD1 clk1_r_REG39_S1 ( .D(in[21]), .E(n56), .CP(wr_clk), .CDN(n115), .Q(
        n478) );
  EDFCNQD1 clk1_r_REG40_S1 ( .D(in[21]), .E(n81), .CP(wr_clk), .CDN(n115), .Q(
        n477) );
  EDFCNQD1 clk1_r_REG41_S1 ( .D(in[21]), .E(n12), .CP(wr_clk), .CDN(n4), .Q(
        n476) );
  EDFCNQD1 clk1_r_REG42_S1 ( .D(in[21]), .E(n83), .CP(wr_clk), .CDN(n4), .Q(
        n475) );
  EDFCNQD1 clk1_r_REG43_S1 ( .D(in[21]), .E(n2), .CP(wr_clk), .CDN(n4), .Q(
        n474) );
  EDFCNQD1 clk1_r_REG44_S1 ( .D(in[21]), .E(n10), .CP(wr_clk), .CDN(n4), .Q(
        n473) );
  EDFCNQD1 clk1_r_REG45_S1 ( .D(in[21]), .E(n7), .CP(wr_clk), .CDN(n4), .Q(
        n472) );
  EDFCNQD1 clk1_r_REG46_S1 ( .D(in[21]), .E(n85), .CP(wr_clk), .CDN(n4), .Q(
        n471) );
  EDFCNQD1 clk1_r_REG47_S1 ( .D(in[21]), .E(n3), .CP(wr_clk), .CDN(n78), .Q(
        n470) );
  EDFCNQD1 clk1_r_REG48_S1 ( .D(in[21]), .E(n9), .CP(wr_clk), .CDN(n115), .Q(
        n469) );
  EDFCNQD1 clk1_r_REG49_S1 ( .D(in[21]), .E(n11), .CP(wr_clk), .CDN(n4), .Q(
        n468) );
  EDFCNQD1 clk1_r_REG50_S1 ( .D(in[21]), .E(n84), .CP(wr_clk), .CDN(n4), .Q(
        n467) );
  EDFCNQD1 clk1_r_REG51_S1 ( .D(in[21]), .E(n14), .CP(wr_clk), .CDN(n4), .Q(
        n466) );
  EDFCNQD1 clk1_r_REG52_S1 ( .D(in[20]), .E(n8), .CP(wr_clk), .CDN(n115), .Q(
        n465) );
  EDFCNQD1 clk1_r_REG53_S1 ( .D(in[20]), .E(n6), .CP(wr_clk), .CDN(n4), .Q(
        n464) );
  EDFCNQD1 clk1_r_REG54_S1 ( .D(in[20]), .E(n86), .CP(wr_clk), .CDN(n4), .Q(
        n463) );
  EDFCNQD1 clk1_r_REG55_S1 ( .D(in[20]), .E(n56), .CP(wr_clk), .CDN(n4), .Q(
        n462) );
  EDFCNQD1 clk1_r_REG56_S1 ( .D(in[20]), .E(n81), .CP(wr_clk), .CDN(n4), .Q(
        n461) );
  EDFCNQD1 clk1_r_REG57_S1 ( .D(in[20]), .E(n12), .CP(wr_clk), .CDN(n115), .Q(
        n460) );
  EDFCNQD1 clk1_r_REG58_S1 ( .D(in[20]), .E(n83), .CP(wr_clk), .CDN(n115), .Q(
        n459) );
  EDFCNQD1 clk1_r_REG59_S1 ( .D(in[20]), .E(n2), .CP(wr_clk), .CDN(n4), .Q(
        n458) );
  EDFCNQD1 clk1_r_REG60_S1 ( .D(in[20]), .E(n10), .CP(wr_clk), .CDN(n4), .Q(
        n457) );
  EDFCNQD1 clk1_r_REG61_S1 ( .D(in[20]), .E(n7), .CP(wr_clk), .CDN(n4), .Q(
        n456) );
  EDFCNQD1 clk1_r_REG62_S1 ( .D(in[20]), .E(n85), .CP(wr_clk), .CDN(n4), .Q(
        n455) );
  EDFCNQD1 clk1_r_REG63_S1 ( .D(in[20]), .E(n3), .CP(wr_clk), .CDN(n115), .Q(
        n454) );
  EDFCNQD1 clk1_r_REG64_S1 ( .D(in[20]), .E(n9), .CP(wr_clk), .CDN(n115), .Q(
        n453) );
  EDFCNQD1 clk1_r_REG65_S1 ( .D(in[20]), .E(n11), .CP(wr_clk), .CDN(n4), .Q(
        n452) );
  EDFCNQD1 clk1_r_REG66_S1 ( .D(in[20]), .E(n84), .CP(wr_clk), .CDN(n4), .Q(
        n451) );
  EDFCNQD1 clk1_r_REG67_S1 ( .D(in[20]), .E(n14), .CP(wr_clk), .CDN(n4), .Q(
        n450) );
  EDFCNQD1 clk1_r_REG68_S1 ( .D(in[19]), .E(n8), .CP(wr_clk), .CDN(n4), .Q(
        n449) );
  EDFCNQD1 clk1_r_REG69_S1 ( .D(in[19]), .E(n6), .CP(wr_clk), .CDN(n4), .Q(
        n448) );
  EDFCNQD1 clk1_r_REG70_S1 ( .D(in[19]), .E(n86), .CP(wr_clk), .CDN(n4), .Q(
        n447) );
  EDFCNQD1 clk1_r_REG71_S1 ( .D(in[19]), .E(n56), .CP(wr_clk), .CDN(n115), .Q(
        n446) );
  EDFCNQD1 clk1_r_REG72_S1 ( .D(in[19]), .E(n82), .CP(wr_clk), .CDN(n4), .Q(
        n445) );
  EDFCNQD1 clk1_r_REG73_S1 ( .D(in[19]), .E(n12), .CP(wr_clk), .CDN(n115), .Q(
        n444) );
  EDFCNQD1 clk1_r_REG74_S1 ( .D(in[19]), .E(n83), .CP(wr_clk), .CDN(n115), .Q(
        n443) );
  EDFCNQD1 clk1_r_REG75_S1 ( .D(in[19]), .E(n2), .CP(wr_clk), .CDN(n115), .Q(
        n442) );
  EDFCNQD1 clk1_r_REG76_S1 ( .D(in[19]), .E(n10), .CP(wr_clk), .CDN(n4), .Q(
        n441) );
  EDFCNQD1 clk1_r_REG77_S1 ( .D(in[19]), .E(n7), .CP(wr_clk), .CDN(n4), .Q(
        n440) );
  EDFCNQD1 clk1_r_REG78_S1 ( .D(in[19]), .E(n85), .CP(wr_clk), .CDN(n4), .Q(
        n439) );
  EDFCNQD1 clk1_r_REG79_S1 ( .D(in[19]), .E(n3), .CP(wr_clk), .CDN(n115), .Q(
        n438) );
  EDFCNQD1 clk1_r_REG80_S1 ( .D(in[19]), .E(n9), .CP(wr_clk), .CDN(n115), .Q(
        n437) );
  EDFCNQD1 clk1_r_REG81_S1 ( .D(in[19]), .E(n11), .CP(wr_clk), .CDN(n4), .Q(
        n436) );
  EDFCNQD1 clk1_r_REG82_S1 ( .D(in[19]), .E(n84), .CP(wr_clk), .CDN(n4), .Q(
        n435) );
  EDFCNQD1 clk1_r_REG83_S1 ( .D(in[19]), .E(n14), .CP(wr_clk), .CDN(n4), .Q(
        n434) );
  EDFCNQD1 clk1_r_REG84_S1 ( .D(in[18]), .E(n8), .CP(wr_clk), .CDN(n115), .Q(
        n433) );
  EDFCNQD1 clk1_r_REG85_S1 ( .D(in[18]), .E(n6), .CP(wr_clk), .CDN(n115), .Q(
        n432) );
  EDFCNQD1 clk1_r_REG86_S1 ( .D(in[18]), .E(n86), .CP(wr_clk), .CDN(n115), .Q(
        n431) );
  EDFCNQD1 clk1_r_REG87_S1 ( .D(in[18]), .E(n56), .CP(wr_clk), .CDN(n115), .Q(
        n430) );
  EDFCNQD1 clk1_r_REG88_S1 ( .D(in[18]), .E(n13), .CP(wr_clk), .CDN(n4), .Q(
        n429) );
  EDFCNQD1 clk1_r_REG89_S1 ( .D(in[18]), .E(n12), .CP(wr_clk), .CDN(n115), .Q(
        n428) );
  EDFCNQD1 clk1_r_REG90_S1 ( .D(in[18]), .E(n83), .CP(wr_clk), .CDN(n4), .Q(
        n427) );
  EDFCNQD1 clk1_r_REG91_S1 ( .D(in[18]), .E(n2), .CP(wr_clk), .CDN(n115), .Q(
        n426) );
  EDFCNQD1 clk1_r_REG92_S1 ( .D(in[18]), .E(n10), .CP(wr_clk), .CDN(n4), .Q(
        n425) );
  EDFCNQD1 clk1_r_REG93_S1 ( .D(in[18]), .E(n7), .CP(wr_clk), .CDN(n115), .Q(
        n424) );
  EDFCNQD1 clk1_r_REG94_S1 ( .D(in[18]), .E(n85), .CP(wr_clk), .CDN(n115), .Q(
        n423) );
  EDFCNQD1 clk1_r_REG95_S1 ( .D(in[18]), .E(n3), .CP(wr_clk), .CDN(n115), .Q(
        n422) );
  EDFCNQD1 clk1_r_REG96_S1 ( .D(in[18]), .E(n9), .CP(wr_clk), .CDN(n4), .Q(
        n421) );
  EDFCNQD1 clk1_r_REG97_S1 ( .D(in[18]), .E(n11), .CP(wr_clk), .CDN(n115), .Q(
        n420) );
  EDFCNQD1 clk1_r_REG98_S1 ( .D(in[18]), .E(n84), .CP(wr_clk), .CDN(n115), .Q(
        n419) );
  EDFCNQD1 clk1_r_REG99_S1 ( .D(in[18]), .E(n14), .CP(wr_clk), .CDN(n115), .Q(
        n418) );
  EDFCNQD1 clk1_r_REG100_S1 ( .D(in[17]), .E(n8), .CP(wr_clk), .CDN(n4), .Q(
        n417) );
  EDFCNQD1 clk1_r_REG101_S1 ( .D(in[17]), .E(n6), .CP(wr_clk), .CDN(n115), .Q(
        n416) );
  EDFCNQD1 clk1_r_REG102_S1 ( .D(in[17]), .E(n86), .CP(wr_clk), .CDN(n4), .Q(
        n415) );
  EDFCNQD1 clk1_r_REG103_S1 ( .D(in[17]), .E(n56), .CP(wr_clk), .CDN(n115), 
        .Q(n414) );
  EDFCNQD1 clk1_r_REG104_S1 ( .D(in[17]), .E(n80), .CP(wr_clk), .CDN(n4), .Q(
        n413) );
  EDFCNQD1 clk1_r_REG105_S1 ( .D(in[17]), .E(n12), .CP(wr_clk), .CDN(n4), .Q(
        n412) );
  EDFCNQD1 clk1_r_REG106_S1 ( .D(in[17]), .E(n83), .CP(wr_clk), .CDN(n115), 
        .Q(n411) );
  EDFCNQD1 clk1_r_REG107_S1 ( .D(in[17]), .E(n2), .CP(wr_clk), .CDN(n4), .Q(
        n410) );
  EDFCNQD1 clk1_r_REG108_S1 ( .D(in[17]), .E(n10), .CP(wr_clk), .CDN(n78), .Q(
        n409) );
  EDFCNQD1 clk1_r_REG109_S1 ( .D(in[17]), .E(n7), .CP(wr_clk), .CDN(n78), .Q(
        n408) );
  EDFCNQD1 clk1_r_REG110_S1 ( .D(in[17]), .E(n85), .CP(wr_clk), .CDN(n4), .Q(
        n407) );
  EDFCNQD1 clk1_r_REG111_S1 ( .D(in[17]), .E(n3), .CP(wr_clk), .CDN(n4), .Q(
        n406) );
  EDFCNQD1 clk1_r_REG112_S1 ( .D(in[17]), .E(n9), .CP(wr_clk), .CDN(n4), .Q(
        n405) );
  EDFCNQD1 clk1_r_REG113_S1 ( .D(in[17]), .E(n11), .CP(wr_clk), .CDN(n115), 
        .Q(n404) );
  EDFCNQD1 clk1_r_REG114_S1 ( .D(in[17]), .E(n84), .CP(wr_clk), .CDN(n4), .Q(
        n403) );
  EDFCNQD1 clk1_r_REG115_S1 ( .D(in[17]), .E(n14), .CP(wr_clk), .CDN(n115), 
        .Q(n402) );
  EDFCNQD1 clk1_r_REG116_S1 ( .D(in[16]), .E(n8), .CP(wr_clk), .CDN(n115), .Q(
        n401) );
  EDFCNQD1 clk1_r_REG117_S1 ( .D(in[16]), .E(n6), .CP(wr_clk), .CDN(n115), .Q(
        n400) );
  EDFCNQD1 clk1_r_REG118_S1 ( .D(in[16]), .E(n86), .CP(wr_clk), .CDN(n4), .Q(
        n399) );
  EDFCNQD1 clk1_r_REG119_S1 ( .D(in[16]), .E(n56), .CP(wr_clk), .CDN(n4), .Q(
        n398) );
  EDFCNQD1 clk1_r_REG120_S1 ( .D(in[16]), .E(n82), .CP(wr_clk), .CDN(n115), 
        .Q(n397) );
  EDFCNQD1 clk1_r_REG121_S1 ( .D(in[16]), .E(n12), .CP(wr_clk), .CDN(n4), .Q(
        n396) );
  EDFCNQD1 clk1_r_REG122_S1 ( .D(in[16]), .E(n83), .CP(wr_clk), .CDN(n4), .Q(
        n395) );
  EDFCNQD1 clk1_r_REG123_S1 ( .D(in[16]), .E(n2), .CP(wr_clk), .CDN(n115), .Q(
        n394) );
  EDFCNQD1 clk1_r_REG124_S1 ( .D(in[16]), .E(n10), .CP(wr_clk), .CDN(n4), .Q(
        n393) );
  EDFCNQD1 clk1_r_REG125_S1 ( .D(in[16]), .E(n7), .CP(wr_clk), .CDN(n4), .Q(
        n392) );
  EDFCNQD1 clk1_r_REG126_S1 ( .D(in[16]), .E(n85), .CP(wr_clk), .CDN(n4), .Q(
        n391) );
  EDFCNQD1 clk1_r_REG127_S1 ( .D(in[16]), .E(n3), .CP(wr_clk), .CDN(n4), .Q(
        n390) );
  EDFCNQD1 clk1_r_REG128_S1 ( .D(in[16]), .E(n9), .CP(wr_clk), .CDN(n4), .Q(
        n389) );
  EDFCNQD1 clk1_r_REG129_S1 ( .D(in[16]), .E(n11), .CP(wr_clk), .CDN(n4), .Q(
        n388) );
  EDFCNQD1 clk1_r_REG130_S1 ( .D(in[16]), .E(n84), .CP(wr_clk), .CDN(n4), .Q(
        n387) );
  EDFCNQD1 clk1_r_REG131_S1 ( .D(in[16]), .E(n14), .CP(wr_clk), .CDN(n115), 
        .Q(n386) );
  EDFCNQD1 clk1_r_REG132_S1 ( .D(in[15]), .E(n8), .CP(wr_clk), .CDN(n4), .Q(
        n385) );
  EDFCNQD1 clk1_r_REG133_S1 ( .D(in[15]), .E(n6), .CP(wr_clk), .CDN(n4), .Q(
        n384) );
  EDFCNQD1 clk1_r_REG134_S1 ( .D(in[15]), .E(n86), .CP(wr_clk), .CDN(n4), .Q(
        n383) );
  EDFCNQD1 clk1_r_REG135_S1 ( .D(in[15]), .E(n56), .CP(wr_clk), .CDN(n4), .Q(
        n382) );
  EDFCNQD1 clk1_r_REG136_S1 ( .D(in[15]), .E(n13), .CP(wr_clk), .CDN(n4), .Q(
        n381) );
  EDFCNQD1 clk1_r_REG137_S1 ( .D(in[15]), .E(n12), .CP(wr_clk), .CDN(n4), .Q(
        n380) );
  EDFCNQD1 clk1_r_REG138_S1 ( .D(in[15]), .E(n83), .CP(wr_clk), .CDN(n4), .Q(
        n379) );
  EDFCNQD1 clk1_r_REG139_S1 ( .D(in[15]), .E(n2), .CP(wr_clk), .CDN(n4), .Q(
        n378) );
  EDFCNQD1 clk1_r_REG140_S1 ( .D(in[15]), .E(n10), .CP(wr_clk), .CDN(n4), .Q(
        n377) );
  EDFCNQD1 clk1_r_REG141_S1 ( .D(in[15]), .E(n7), .CP(wr_clk), .CDN(n4), .Q(
        n376) );
  EDFCNQD1 clk1_r_REG142_S1 ( .D(in[15]), .E(n85), .CP(wr_clk), .CDN(n4), .Q(
        n375) );
  EDFCNQD1 clk1_r_REG143_S1 ( .D(in[15]), .E(n3), .CP(wr_clk), .CDN(n4), .Q(
        n374) );
  EDFCNQD1 clk1_r_REG144_S1 ( .D(in[15]), .E(n9), .CP(wr_clk), .CDN(n4), .Q(
        n373) );
  EDFCNQD1 clk1_r_REG145_S1 ( .D(in[15]), .E(n11), .CP(wr_clk), .CDN(n4), .Q(
        n372) );
  EDFCNQD1 clk1_r_REG146_S1 ( .D(in[15]), .E(n84), .CP(wr_clk), .CDN(n4), .Q(
        n371) );
  EDFCNQD1 clk1_r_REG147_S1 ( .D(in[15]), .E(n14), .CP(wr_clk), .CDN(n4), .Q(
        n370) );
  EDFCNQD1 clk1_r_REG148_S1 ( .D(in[14]), .E(n8), .CP(wr_clk), .CDN(n4), .Q(
        n369) );
  EDFCNQD1 clk1_r_REG149_S1 ( .D(in[14]), .E(n6), .CP(wr_clk), .CDN(n4), .Q(
        n368) );
  EDFCNQD1 clk1_r_REG150_S1 ( .D(in[14]), .E(n86), .CP(wr_clk), .CDN(n4), .Q(
        n367) );
  EDFCNQD1 clk1_r_REG151_S1 ( .D(in[14]), .E(n56), .CP(wr_clk), .CDN(n4), .Q(
        n366) );
  EDFCNQD1 clk1_r_REG152_S1 ( .D(in[14]), .E(n81), .CP(wr_clk), .CDN(n4), .Q(
        n365) );
  EDFCNQD1 clk1_r_REG153_S1 ( .D(in[14]), .E(n12), .CP(wr_clk), .CDN(n78), .Q(
        n364) );
  EDFCNQD1 clk1_r_REG154_S1 ( .D(in[14]), .E(n83), .CP(wr_clk), .CDN(n4), .Q(
        n363) );
  EDFCNQD1 clk1_r_REG155_S1 ( .D(in[14]), .E(n2), .CP(wr_clk), .CDN(n4), .Q(
        n362) );
  EDFCNQD1 clk1_r_REG156_S1 ( .D(in[14]), .E(n10), .CP(wr_clk), .CDN(n115), 
        .Q(n361) );
  EDFCNQD1 clk1_r_REG157_S1 ( .D(in[14]), .E(n7), .CP(wr_clk), .CDN(n4), .Q(
        n360) );
  EDFCNQD1 clk1_r_REG158_S1 ( .D(in[14]), .E(n85), .CP(wr_clk), .CDN(n115), 
        .Q(n359) );
  EDFCNQD1 clk1_r_REG159_S1 ( .D(in[14]), .E(n3), .CP(wr_clk), .CDN(n115), .Q(
        n358) );
  EDFCNQD1 clk1_r_REG160_S1 ( .D(in[14]), .E(n9), .CP(wr_clk), .CDN(n4), .Q(
        n357) );
  EDFCNQD1 clk1_r_REG161_S1 ( .D(in[14]), .E(n11), .CP(wr_clk), .CDN(n4), .Q(
        n356) );
  EDFCNQD1 clk1_r_REG162_S1 ( .D(in[14]), .E(n84), .CP(wr_clk), .CDN(n4), .Q(
        n355) );
  EDFCNQD1 clk1_r_REG163_S1 ( .D(in[14]), .E(n14), .CP(wr_clk), .CDN(n4), .Q(
        n354) );
  EDFCNQD1 clk1_r_REG164_S1 ( .D(in[13]), .E(n8), .CP(wr_clk), .CDN(n4), .Q(
        n353) );
  EDFCNQD1 clk1_r_REG165_S1 ( .D(in[13]), .E(n6), .CP(wr_clk), .CDN(n78), .Q(
        n352) );
  EDFCNQD1 clk1_r_REG166_S1 ( .D(in[13]), .E(n86), .CP(wr_clk), .CDN(n4), .Q(
        n351) );
  EDFCNQD1 clk1_r_REG167_S1 ( .D(in[13]), .E(n56), .CP(wr_clk), .CDN(n78), .Q(
        n350) );
  EDFCNQD1 clk1_r_REG168_S1 ( .D(in[13]), .E(n82), .CP(wr_clk), .CDN(n4), .Q(
        n349) );
  EDFCNQD1 clk1_r_REG169_S1 ( .D(in[13]), .E(n12), .CP(wr_clk), .CDN(n78), .Q(
        n348) );
  EDFCNQD1 clk1_r_REG170_S1 ( .D(in[13]), .E(n83), .CP(wr_clk), .CDN(n115), 
        .Q(n347) );
  EDFCNQD1 clk1_r_REG171_S1 ( .D(in[13]), .E(n2), .CP(wr_clk), .CDN(n78), .Q(
        n346) );
  EDFCNQD1 clk1_r_REG172_S1 ( .D(in[13]), .E(n10), .CP(wr_clk), .CDN(n4), .Q(
        n345) );
  EDFCNQD1 clk1_r_REG173_S1 ( .D(in[13]), .E(n7), .CP(wr_clk), .CDN(n78), .Q(
        n344) );
  EDFCNQD1 clk1_r_REG174_S1 ( .D(in[13]), .E(n85), .CP(wr_clk), .CDN(n4), .Q(
        n343) );
  EDFCNQD1 clk1_r_REG175_S1 ( .D(in[13]), .E(n3), .CP(wr_clk), .CDN(n78), .Q(
        n342) );
  EDFCNQD1 clk1_r_REG176_S1 ( .D(in[13]), .E(n9), .CP(wr_clk), .CDN(n4), .Q(
        n341) );
  EDFCNQD1 clk1_r_REG177_S1 ( .D(in[13]), .E(n11), .CP(wr_clk), .CDN(n78), .Q(
        n340) );
  EDFCNQD1 clk1_r_REG178_S1 ( .D(in[13]), .E(n84), .CP(wr_clk), .CDN(n115), 
        .Q(n339) );
  EDFCNQD1 clk1_r_REG179_S1 ( .D(in[13]), .E(n14), .CP(wr_clk), .CDN(n78), .Q(
        n338) );
  EDFCNQD1 clk1_r_REG180_S1 ( .D(in[12]), .E(n8), .CP(wr_clk), .CDN(n4), .Q(
        n337) );
  EDFCNQD1 clk1_r_REG181_S1 ( .D(in[12]), .E(n6), .CP(wr_clk), .CDN(n78), .Q(
        n336) );
  EDFCNQD1 clk1_r_REG182_S1 ( .D(in[12]), .E(n86), .CP(wr_clk), .CDN(n4), .Q(
        n335) );
  EDFCNQD1 clk1_r_REG183_S1 ( .D(in[12]), .E(n56), .CP(wr_clk), .CDN(n78), .Q(
        n334) );
  EDFCNQD1 clk1_r_REG184_S1 ( .D(in[12]), .E(n13), .CP(wr_clk), .CDN(n4), .Q(
        n333) );
  EDFCNQD1 clk1_r_REG185_S1 ( .D(in[12]), .E(n12), .CP(wr_clk), .CDN(n115), 
        .Q(n332) );
  EDFCNQD1 clk1_r_REG186_S1 ( .D(in[12]), .E(n83), .CP(wr_clk), .CDN(n4), .Q(
        n331) );
  EDFCNQD1 clk1_r_REG187_S1 ( .D(in[12]), .E(n2), .CP(wr_clk), .CDN(n115), .Q(
        n330) );
  EDFCNQD1 clk1_r_REG188_S1 ( .D(in[12]), .E(n10), .CP(wr_clk), .CDN(n4), .Q(
        n329) );
  EDFCNQD1 clk1_r_REG189_S1 ( .D(in[12]), .E(n7), .CP(wr_clk), .CDN(n115), .Q(
        n328) );
  EDFCNQD1 clk1_r_REG190_S1 ( .D(in[12]), .E(n85), .CP(wr_clk), .CDN(n4), .Q(
        n327) );
  EDFCNQD1 clk1_r_REG191_S1 ( .D(in[12]), .E(n3), .CP(wr_clk), .CDN(n78), .Q(
        n326) );
  EDFCNQD1 clk1_r_REG192_S1 ( .D(in[12]), .E(n9), .CP(wr_clk), .CDN(n4), .Q(
        n325) );
  EDFCNQD1 clk1_r_REG193_S1 ( .D(in[12]), .E(n11), .CP(wr_clk), .CDN(n78), .Q(
        n324) );
  EDFCNQD1 clk1_r_REG194_S1 ( .D(in[12]), .E(n84), .CP(wr_clk), .CDN(n4), .Q(
        n323) );
  EDFCNQD1 clk1_r_REG195_S1 ( .D(in[12]), .E(n14), .CP(wr_clk), .CDN(n78), .Q(
        n322) );
  EDFCNQD1 clk1_r_REG196_S1 ( .D(in[11]), .E(n8), .CP(wr_clk), .CDN(n4), .Q(
        n321) );
  EDFCNQD1 clk1_r_REG197_S1 ( .D(in[11]), .E(n6), .CP(wr_clk), .CDN(n115), .Q(
        n320) );
  EDFCNQD1 clk1_r_REG198_S1 ( .D(in[11]), .E(n86), .CP(wr_clk), .CDN(n4), .Q(
        n319) );
  EDFCNQD1 clk1_r_REG199_S1 ( .D(in[11]), .E(n56), .CP(wr_clk), .CDN(n115), 
        .Q(n318) );
  EDFCNQD1 clk1_r_REG200_S1 ( .D(in[11]), .E(n80), .CP(wr_clk), .CDN(n4), .Q(
        n317) );
  EDFCNQD1 clk1_r_REG201_S1 ( .D(in[11]), .E(n12), .CP(wr_clk), .CDN(n4), .Q(
        n316) );
  EDFCNQD1 clk1_r_REG202_S1 ( .D(in[11]), .E(n83), .CP(wr_clk), .CDN(n4), .Q(
        n315) );
  EDFCNQD1 clk1_r_REG203_S1 ( .D(in[11]), .E(n2), .CP(wr_clk), .CDN(n115), .Q(
        n314) );
  EDFCNQD1 clk1_r_REG204_S1 ( .D(in[11]), .E(n10), .CP(wr_clk), .CDN(n4), .Q(
        n313) );
  EDFCNQD1 clk1_r_REG205_S1 ( .D(in[11]), .E(n7), .CP(wr_clk), .CDN(n115), .Q(
        n312) );
  EDFCNQD1 clk1_r_REG206_S1 ( .D(in[11]), .E(n85), .CP(wr_clk), .CDN(n4), .Q(
        n311) );
  EDFCNQD1 clk1_r_REG207_S1 ( .D(in[11]), .E(n3), .CP(wr_clk), .CDN(n115), .Q(
        n310) );
  EDFCNQD1 clk1_r_REG208_S1 ( .D(in[11]), .E(n9), .CP(wr_clk), .CDN(n4), .Q(
        n309) );
  EDFCNQD1 clk1_r_REG209_S1 ( .D(in[11]), .E(n11), .CP(wr_clk), .CDN(n115), 
        .Q(n308) );
  EDFCNQD1 clk1_r_REG210_S1 ( .D(in[11]), .E(n84), .CP(wr_clk), .CDN(n4), .Q(
        n307) );
  EDFCNQD1 clk1_r_REG211_S1 ( .D(in[11]), .E(n14), .CP(wr_clk), .CDN(n115), 
        .Q(n306) );
  EDFCNQD1 clk1_r_REG212_S1 ( .D(in[10]), .E(n8), .CP(wr_clk), .CDN(n4), .Q(
        n305) );
  EDFCNQD1 clk1_r_REG213_S1 ( .D(in[10]), .E(n6), .CP(wr_clk), .CDN(n4), .Q(
        n304) );
  EDFCNQD1 clk1_r_REG214_S1 ( .D(in[10]), .E(n86), .CP(wr_clk), .CDN(n115), 
        .Q(n303) );
  EDFCNQD1 clk1_r_REG215_S1 ( .D(in[10]), .E(n56), .CP(wr_clk), .CDN(n4), .Q(
        n302) );
  EDFCNQD1 clk1_r_REG216_S1 ( .D(in[10]), .E(n13), .CP(wr_clk), .CDN(n115), 
        .Q(n301) );
  EDFCNQD1 clk1_r_REG217_S1 ( .D(in[10]), .E(n12), .CP(wr_clk), .CDN(n4), .Q(
        n300) );
  EDFCNQD1 clk1_r_REG218_S1 ( .D(in[10]), .E(n83), .CP(wr_clk), .CDN(n4), .Q(
        n299) );
  EDFCNQD1 clk1_r_REG219_S1 ( .D(in[10]), .E(n2), .CP(wr_clk), .CDN(n4), .Q(
        n298) );
  EDFCNQD1 clk1_r_REG220_S1 ( .D(in[10]), .E(n10), .CP(wr_clk), .CDN(n4), .Q(
        n297) );
  EDFCNQD1 clk1_r_REG221_S1 ( .D(in[10]), .E(n7), .CP(wr_clk), .CDN(n4), .Q(
        n296) );
  EDFCNQD1 clk1_r_REG222_S1 ( .D(in[10]), .E(n85), .CP(wr_clk), .CDN(n4), .Q(
        n295) );
  EDFCNQD1 clk1_r_REG223_S1 ( .D(in[10]), .E(n3), .CP(wr_clk), .CDN(n4), .Q(
        n294) );
  EDFCNQD1 clk1_r_REG224_S1 ( .D(in[10]), .E(n9), .CP(wr_clk), .CDN(n4), .Q(
        n293) );
  EDFCNQD1 clk1_r_REG225_S1 ( .D(in[10]), .E(n11), .CP(wr_clk), .CDN(n4), .Q(
        n292) );
  EDFCNQD1 clk1_r_REG226_S1 ( .D(in[10]), .E(n84), .CP(wr_clk), .CDN(n4), .Q(
        n291) );
  EDFCNQD1 clk1_r_REG227_S1 ( .D(in[10]), .E(n14), .CP(wr_clk), .CDN(n4), .Q(
        n290) );
  EDFCNQD1 clk1_r_REG228_S1 ( .D(in[9]), .E(n8), .CP(wr_clk), .CDN(n4), .Q(
        n289) );
  EDFCNQD1 clk1_r_REG229_S1 ( .D(in[9]), .E(n6), .CP(wr_clk), .CDN(n4), .Q(
        n288) );
  EDFCNQD1 clk1_r_REG230_S1 ( .D(in[9]), .E(n86), .CP(wr_clk), .CDN(n78), .Q(
        n287) );
  EDFCNQD1 clk1_r_REG231_S1 ( .D(in[9]), .E(n56), .CP(wr_clk), .CDN(n4), .Q(
        n286) );
  EDFCNQD1 clk1_r_REG232_S1 ( .D(in[9]), .E(n81), .CP(wr_clk), .CDN(n4), .Q(
        n285) );
  EDFCNQD1 clk1_r_REG233_S1 ( .D(in[9]), .E(n12), .CP(wr_clk), .CDN(n4), .Q(
        n284) );
  EDFCNQD1 clk1_r_REG234_S1 ( .D(in[9]), .E(n83), .CP(wr_clk), .CDN(n115), .Q(
        n283) );
  EDFCNQD1 clk1_r_REG235_S1 ( .D(in[9]), .E(n2), .CP(wr_clk), .CDN(n4), .Q(
        n282) );
  EDFCNQD1 clk1_r_REG236_S1 ( .D(in[9]), .E(n10), .CP(wr_clk), .CDN(n115), .Q(
        n281) );
  EDFCNQD1 clk1_r_REG237_S1 ( .D(in[9]), .E(n7), .CP(wr_clk), .CDN(n4), .Q(
        n280) );
  EDFCNQD1 clk1_r_REG238_S1 ( .D(in[9]), .E(n85), .CP(wr_clk), .CDN(n115), .Q(
        n279) );
  EDFCNQD1 clk1_r_REG239_S1 ( .D(in[9]), .E(n3), .CP(wr_clk), .CDN(n4), .Q(
        n278) );
  EDFCNQD1 clk1_r_REG240_S1 ( .D(in[9]), .E(n9), .CP(wr_clk), .CDN(n4), .Q(
        n277) );
  EDFCNQD1 clk1_r_REG241_S1 ( .D(in[9]), .E(n11), .CP(wr_clk), .CDN(n4), .Q(
        n276) );
  EDFCNQD1 clk1_r_REG242_S1 ( .D(in[9]), .E(n84), .CP(wr_clk), .CDN(n115), .Q(
        n275) );
  EDFCNQD1 clk1_r_REG243_S1 ( .D(in[9]), .E(n14), .CP(wr_clk), .CDN(n4), .Q(
        n274) );
  EDFCNQD1 clk1_r_REG244_S1 ( .D(in[8]), .E(n8), .CP(wr_clk), .CDN(n4), .Q(
        n273) );
  EDFCNQD1 clk1_r_REG245_S1 ( .D(in[8]), .E(n6), .CP(wr_clk), .CDN(n4), .Q(
        n272) );
  EDFCNQD1 clk1_r_REG246_S1 ( .D(in[8]), .E(n86), .CP(wr_clk), .CDN(n115), .Q(
        n271) );
  EDFCNQD1 clk1_r_REG247_S1 ( .D(in[8]), .E(n56), .CP(wr_clk), .CDN(n4), .Q(
        n270) );
  EDFCNQD1 clk1_r_REG248_S1 ( .D(in[8]), .E(n82), .CP(wr_clk), .CDN(n4), .Q(
        n269) );
  EDFCNQD1 clk1_r_REG249_S1 ( .D(in[8]), .E(n12), .CP(wr_clk), .CDN(n78), .Q(
        n268) );
  EDFCNQD1 clk1_r_REG250_S1 ( .D(in[8]), .E(n83), .CP(wr_clk), .CDN(n4), .Q(
        n267) );
  EDFCNQD1 clk1_r_REG251_S1 ( .D(in[8]), .E(n2), .CP(wr_clk), .CDN(n115), .Q(
        n266) );
  EDFCNQD1 clk1_r_REG252_S1 ( .D(in[8]), .E(n10), .CP(wr_clk), .CDN(n4), .Q(
        n265) );
  EDFCNQD1 clk1_r_REG253_S1 ( .D(in[8]), .E(n7), .CP(wr_clk), .CDN(n4), .Q(
        n264) );
  EDFCNQD1 clk1_r_REG254_S1 ( .D(in[8]), .E(n85), .CP(wr_clk), .CDN(n4), .Q(
        n263) );
  EDFCNQD1 clk1_r_REG255_S1 ( .D(in[8]), .E(n3), .CP(wr_clk), .CDN(n115), .Q(
        n262) );
  EDFCNQD1 clk1_r_REG256_S1 ( .D(in[8]), .E(n9), .CP(wr_clk), .CDN(n4), .Q(
        n261) );
  EDFCNQD1 clk1_r_REG257_S1 ( .D(in[8]), .E(n11), .CP(wr_clk), .CDN(n115), .Q(
        n260) );
  EDFCNQD1 clk1_r_REG258_S1 ( .D(in[8]), .E(n84), .CP(wr_clk), .CDN(n115), .Q(
        n259) );
  EDFCNQD1 clk1_r_REG259_S1 ( .D(in[8]), .E(n14), .CP(wr_clk), .CDN(n4), .Q(
        n258) );
  EDFCNQD1 clk1_r_REG260_S1 ( .D(in[7]), .E(n8), .CP(wr_clk), .CDN(n4), .Q(
        n257) );
  EDFCNQD1 clk1_r_REG261_S1 ( .D(in[7]), .E(n6), .CP(wr_clk), .CDN(n4), .Q(
        n256) );
  EDFCNQD1 clk1_r_REG262_S1 ( .D(in[7]), .E(n86), .CP(wr_clk), .CDN(n115), .Q(
        n255) );
  EDFCNQD1 clk1_r_REG263_S1 ( .D(in[7]), .E(n56), .CP(wr_clk), .CDN(n4), .Q(
        n254) );
  EDFCNQD1 clk1_r_REG264_S1 ( .D(in[7]), .E(n80), .CP(wr_clk), .CDN(n4), .Q(
        n253) );
  EDFCNQD1 clk1_r_REG265_S1 ( .D(in[7]), .E(n12), .CP(wr_clk), .CDN(n115), .Q(
        n252) );
  EDFCNQD1 clk1_r_REG266_S1 ( .D(in[7]), .E(n83), .CP(wr_clk), .CDN(n4), .Q(
        n251) );
  EDFCNQD1 clk1_r_REG267_S1 ( .D(in[7]), .E(n2), .CP(wr_clk), .CDN(n4), .Q(
        n250) );
  EDFCNQD1 clk1_r_REG268_S1 ( .D(in[7]), .E(n10), .CP(wr_clk), .CDN(n4), .Q(
        n249) );
  EDFCNQD1 clk1_r_REG269_S1 ( .D(in[7]), .E(n7), .CP(wr_clk), .CDN(n4), .Q(
        n248) );
  EDFCNQD1 clk1_r_REG270_S1 ( .D(in[7]), .E(n85), .CP(wr_clk), .CDN(n4), .Q(
        n247) );
  EDFCNQD1 clk1_r_REG271_S1 ( .D(in[7]), .E(n3), .CP(wr_clk), .CDN(n4), .Q(
        n246) );
  EDFCNQD1 clk1_r_REG272_S1 ( .D(in[7]), .E(n9), .CP(wr_clk), .CDN(n4), .Q(
        n245) );
  EDFCNQD1 clk1_r_REG273_S1 ( .D(in[7]), .E(n11), .CP(wr_clk), .CDN(n115), .Q(
        n244) );
  EDFCNQD1 clk1_r_REG274_S1 ( .D(in[7]), .E(n84), .CP(wr_clk), .CDN(n4), .Q(
        n243) );
  EDFCNQD1 clk1_r_REG275_S1 ( .D(in[7]), .E(n14), .CP(wr_clk), .CDN(n4), .Q(
        n242) );
  EDFCNQD1 clk1_r_REG276_S1 ( .D(in[6]), .E(n8), .CP(wr_clk), .CDN(n4), .Q(
        n241) );
  EDFCNQD1 clk1_r_REG277_S1 ( .D(in[6]), .E(n6), .CP(wr_clk), .CDN(n4), .Q(
        n240) );
  EDFCNQD1 clk1_r_REG278_S1 ( .D(in[6]), .E(n86), .CP(wr_clk), .CDN(n4), .Q(
        n239) );
  EDFCNQD1 clk1_r_REG279_S1 ( .D(in[6]), .E(n56), .CP(wr_clk), .CDN(n4), .Q(
        n238) );
  EDFCNQD1 clk1_r_REG280_S1 ( .D(in[6]), .E(n13), .CP(wr_clk), .CDN(n4), .Q(
        n237) );
  EDFCNQD1 clk1_r_REG281_S1 ( .D(in[6]), .E(n12), .CP(wr_clk), .CDN(n4), .Q(
        n236) );
  EDFCNQD1 clk1_r_REG282_S1 ( .D(in[6]), .E(n83), .CP(wr_clk), .CDN(n4), .Q(
        n235) );
  EDFCNQD1 clk1_r_REG283_S1 ( .D(in[6]), .E(n2), .CP(wr_clk), .CDN(n4), .Q(
        n234) );
  EDFCNQD1 clk1_r_REG284_S1 ( .D(in[6]), .E(n10), .CP(wr_clk), .CDN(n4), .Q(
        n233) );
  EDFCNQD1 clk1_r_REG285_S1 ( .D(in[6]), .E(n7), .CP(wr_clk), .CDN(n4), .Q(
        n232) );
  EDFCNQD1 clk1_r_REG286_S1 ( .D(in[6]), .E(n85), .CP(wr_clk), .CDN(n4), .Q(
        n231) );
  EDFCNQD1 clk1_r_REG287_S1 ( .D(in[6]), .E(n3), .CP(wr_clk), .CDN(n115), .Q(
        n230) );
  EDFCNQD1 clk1_r_REG288_S1 ( .D(in[6]), .E(n9), .CP(wr_clk), .CDN(n4), .Q(
        n229) );
  EDFCNQD1 clk1_r_REG289_S1 ( .D(in[6]), .E(n11), .CP(wr_clk), .CDN(n4), .Q(
        n228) );
  EDFCNQD1 clk1_r_REG290_S1 ( .D(in[6]), .E(n84), .CP(wr_clk), .CDN(n4), .Q(
        n227) );
  EDFCNQD1 clk1_r_REG291_S1 ( .D(in[6]), .E(n14), .CP(wr_clk), .CDN(n4), .Q(
        n226) );
  EDFCNQD1 clk1_r_REG292_S1 ( .D(in[5]), .E(n8), .CP(wr_clk), .CDN(n4), .Q(
        n225) );
  EDFCNQD1 clk1_r_REG293_S1 ( .D(in[5]), .E(n6), .CP(wr_clk), .CDN(n4), .Q(
        n224) );
  EDFCNQD1 clk1_r_REG294_S1 ( .D(in[5]), .E(n86), .CP(wr_clk), .CDN(n4), .Q(
        n223) );
  EDFCNQD1 clk1_r_REG295_S1 ( .D(in[5]), .E(n56), .CP(wr_clk), .CDN(n115), .Q(
        n222) );
  EDFCNQD1 clk1_r_REG296_S1 ( .D(in[5]), .E(n80), .CP(wr_clk), .CDN(n4), .Q(
        n221) );
  EDFCNQD1 clk1_r_REG297_S1 ( .D(in[5]), .E(n12), .CP(wr_clk), .CDN(n4), .Q(
        n220) );
  EDFCNQD1 clk1_r_REG298_S1 ( .D(in[5]), .E(n83), .CP(wr_clk), .CDN(n4), .Q(
        n219) );
  EDFCNQD1 clk1_r_REG299_S1 ( .D(in[5]), .E(n2), .CP(wr_clk), .CDN(n4), .Q(
        n218) );
  EDFCNQD1 clk1_r_REG300_S1 ( .D(in[5]), .E(n10), .CP(wr_clk), .CDN(n4), .Q(
        n217) );
  EDFCNQD1 clk1_r_REG301_S1 ( .D(in[5]), .E(n7), .CP(wr_clk), .CDN(n4), .Q(
        n216) );
  EDFCNQD1 clk1_r_REG302_S1 ( .D(in[5]), .E(n85), .CP(wr_clk), .CDN(n4), .Q(
        n215) );
  EDFCNQD1 clk1_r_REG303_S1 ( .D(in[5]), .E(n3), .CP(wr_clk), .CDN(n4), .Q(
        n214) );
  EDFCNQD1 clk1_r_REG304_S1 ( .D(in[5]), .E(n9), .CP(wr_clk), .CDN(n4), .Q(
        n213) );
  EDFCNQD1 clk1_r_REG305_S1 ( .D(in[5]), .E(n11), .CP(wr_clk), .CDN(n4), .Q(
        n212) );
  EDFCNQD1 clk1_r_REG306_S1 ( .D(in[5]), .E(n84), .CP(wr_clk), .CDN(n4), .Q(
        n211) );
  EDFCNQD1 clk1_r_REG307_S1 ( .D(in[5]), .E(n14), .CP(wr_clk), .CDN(n4), .Q(
        n210) );
  EDFCNQD1 clk1_r_REG308_S1 ( .D(in[4]), .E(n8), .CP(wr_clk), .CDN(n4), .Q(
        n209) );
  EDFCNQD1 clk1_r_REG309_S1 ( .D(in[4]), .E(n6), .CP(wr_clk), .CDN(n4), .Q(
        n208) );
  EDFCNQD1 clk1_r_REG310_S1 ( .D(in[4]), .E(n86), .CP(wr_clk), .CDN(n4), .Q(
        n207) );
  EDFCNQD1 clk1_r_REG311_S1 ( .D(in[4]), .E(n56), .CP(wr_clk), .CDN(n4), .Q(
        n206) );
  EDFCNQD1 clk1_r_REG312_S1 ( .D(in[4]), .E(n13), .CP(wr_clk), .CDN(n4), .Q(
        n205) );
  EDFCNQD1 clk1_r_REG313_S1 ( .D(in[4]), .E(n12), .CP(wr_clk), .CDN(n115), .Q(
        n204) );
  EDFCNQD1 clk1_r_REG314_S1 ( .D(in[4]), .E(n83), .CP(wr_clk), .CDN(n4), .Q(
        n203) );
  EDFCNQD1 clk1_r_REG315_S1 ( .D(in[4]), .E(n2), .CP(wr_clk), .CDN(n4), .Q(
        n202) );
  EDFCNQD1 clk1_r_REG316_S1 ( .D(in[4]), .E(n10), .CP(wr_clk), .CDN(n4), .Q(
        n201) );
  EDFCNQD1 clk1_r_REG317_S1 ( .D(in[4]), .E(n7), .CP(wr_clk), .CDN(n4), .Q(
        n200) );
  EDFCNQD1 clk1_r_REG318_S1 ( .D(in[4]), .E(n85), .CP(wr_clk), .CDN(n4), .Q(
        n199) );
  EDFCNQD1 clk1_r_REG319_S1 ( .D(in[4]), .E(n3), .CP(wr_clk), .CDN(n4), .Q(
        n198) );
  EDFCNQD1 clk1_r_REG320_S1 ( .D(in[4]), .E(n9), .CP(wr_clk), .CDN(n4), .Q(
        n197) );
  EDFCNQD1 clk1_r_REG321_S1 ( .D(in[4]), .E(n11), .CP(wr_clk), .CDN(n4), .Q(
        n196) );
  EDFCNQD1 clk1_r_REG322_S1 ( .D(in[4]), .E(n84), .CP(wr_clk), .CDN(n4), .Q(
        n195) );
  EDFCNQD1 clk1_r_REG323_S1 ( .D(in[4]), .E(n14), .CP(wr_clk), .CDN(n4), .Q(
        n194) );
  EDFCNQD1 clk1_r_REG324_S1 ( .D(in[3]), .E(n8), .CP(wr_clk), .CDN(n4), .Q(
        n193) );
  EDFCNQD1 clk1_r_REG325_S1 ( .D(in[3]), .E(n6), .CP(wr_clk), .CDN(n115), .Q(
        n192) );
  EDFCNQD1 clk1_r_REG326_S1 ( .D(in[3]), .E(n86), .CP(wr_clk), .CDN(n4), .Q(
        n191) );
  EDFCNQD1 clk1_r_REG327_S1 ( .D(in[3]), .E(n56), .CP(wr_clk), .CDN(n115), .Q(
        n190) );
  EDFCNQD1 clk1_r_REG328_S1 ( .D(in[3]), .E(n81), .CP(wr_clk), .CDN(n4), .Q(
        n189) );
  EDFCNQD1 clk1_r_REG329_S1 ( .D(in[3]), .E(n12), .CP(wr_clk), .CDN(n115), .Q(
        n188) );
  EDFCNQD1 clk1_r_REG330_S1 ( .D(in[3]), .E(n83), .CP(wr_clk), .CDN(n115), .Q(
        n187) );
  EDFCNQD1 clk1_r_REG331_S1 ( .D(in[3]), .E(n2), .CP(wr_clk), .CDN(n115), .Q(
        n186) );
  EDFCNQD1 clk1_r_REG332_S1 ( .D(in[3]), .E(n10), .CP(wr_clk), .CDN(n4), .Q(
        n185) );
  EDFCNQD1 clk1_r_REG333_S1 ( .D(in[3]), .E(n7), .CP(wr_clk), .CDN(n115), .Q(
        n184) );
  EDFCNQD1 clk1_r_REG334_S1 ( .D(in[3]), .E(n85), .CP(wr_clk), .CDN(n4), .Q(
        n183) );
  EDFCNQD1 clk1_r_REG335_S1 ( .D(in[3]), .E(n3), .CP(wr_clk), .CDN(n115), .Q(
        n182) );
  EDFCNQD1 clk1_r_REG336_S1 ( .D(in[3]), .E(n9), .CP(wr_clk), .CDN(n4), .Q(
        n181) );
  EDFCNQD1 clk1_r_REG337_S1 ( .D(in[3]), .E(n11), .CP(wr_clk), .CDN(n115), .Q(
        n180) );
  EDFCNQD1 clk1_r_REG338_S1 ( .D(in[3]), .E(n84), .CP(wr_clk), .CDN(n115), .Q(
        n179) );
  EDFCNQD1 clk1_r_REG339_S1 ( .D(in[3]), .E(n14), .CP(wr_clk), .CDN(n115), .Q(
        n178) );
  EDFCNQD1 clk1_r_REG340_S1 ( .D(in[2]), .E(n8), .CP(wr_clk), .CDN(n4), .Q(
        n177) );
  EDFCNQD1 clk1_r_REG341_S1 ( .D(in[2]), .E(n6), .CP(wr_clk), .CDN(n4), .Q(
        n176) );
  EDFCNQD1 clk1_r_REG342_S1 ( .D(in[2]), .E(n86), .CP(wr_clk), .CDN(n115), .Q(
        n175) );
  EDFCNQD1 clk1_r_REG343_S1 ( .D(in[2]), .E(n56), .CP(wr_clk), .CDN(n115), .Q(
        n174) );
  EDFCNQD1 clk1_r_REG344_S1 ( .D(in[2]), .E(n13), .CP(wr_clk), .CDN(n115), .Q(
        n173) );
  EDFCNQD1 clk1_r_REG345_S1 ( .D(in[2]), .E(n12), .CP(wr_clk), .CDN(n4), .Q(
        n172) );
  EDFCNQD1 clk1_r_REG346_S1 ( .D(in[2]), .E(n83), .CP(wr_clk), .CDN(n4), .Q(
        n171) );
  EDFCNQD1 clk1_r_REG347_S1 ( .D(in[2]), .E(n2), .CP(wr_clk), .CDN(n4), .Q(
        n170) );
  EDFCNQD1 clk1_r_REG348_S1 ( .D(in[2]), .E(n10), .CP(wr_clk), .CDN(n4), .Q(
        n169) );
  EDFCNQD1 clk1_r_REG349_S1 ( .D(in[2]), .E(n7), .CP(wr_clk), .CDN(n115), .Q(
        n168) );
  EDFCNQD1 clk1_r_REG350_S1 ( .D(in[2]), .E(n85), .CP(wr_clk), .CDN(n115), .Q(
        n167) );
  EDFCNQD1 clk1_r_REG351_S1 ( .D(in[2]), .E(n3), .CP(wr_clk), .CDN(n78), .Q(
        n166) );
  EDFCNQD1 clk1_r_REG352_S1 ( .D(in[2]), .E(n9), .CP(wr_clk), .CDN(n4), .Q(
        n165) );
  EDFCNQD1 clk1_r_REG353_S1 ( .D(in[2]), .E(n11), .CP(wr_clk), .CDN(n115), .Q(
        n164) );
  EDFCNQD1 clk1_r_REG354_S1 ( .D(in[2]), .E(n84), .CP(wr_clk), .CDN(n115), .Q(
        n163) );
  EDFCNQD1 clk1_r_REG355_S1 ( .D(in[2]), .E(n14), .CP(wr_clk), .CDN(n4), .Q(
        n162) );
  EDFCNQD1 clk1_r_REG356_S1 ( .D(in[1]), .E(n8), .CP(wr_clk), .CDN(n4), .Q(
        n161) );
  EDFCNQD1 clk1_r_REG357_S1 ( .D(in[1]), .E(n6), .CP(wr_clk), .CDN(n115), .Q(
        n160) );
  EDFCNQD1 clk1_r_REG358_S1 ( .D(in[1]), .E(n86), .CP(wr_clk), .CDN(n4), .Q(
        n159) );
  EDFCNQD1 clk1_r_REG359_S1 ( .D(in[1]), .E(n56), .CP(wr_clk), .CDN(n4), .Q(
        n158) );
  EDFCNQD1 clk1_r_REG360_S1 ( .D(in[1]), .E(n82), .CP(wr_clk), .CDN(n4), .Q(
        n157) );
  EDFCNQD1 clk1_r_REG361_S1 ( .D(in[1]), .E(n12), .CP(wr_clk), .CDN(n115), .Q(
        n156) );
  EDFCNQD1 clk1_r_REG362_S1 ( .D(in[1]), .E(n83), .CP(wr_clk), .CDN(n4), .Q(
        n155) );
  EDFCNQD1 clk1_r_REG363_S1 ( .D(in[1]), .E(n2), .CP(wr_clk), .CDN(n4), .Q(
        n154) );
  EDFCNQD1 clk1_r_REG364_S1 ( .D(in[1]), .E(n10), .CP(wr_clk), .CDN(n4), .Q(
        n153) );
  EDFCNQD1 clk1_r_REG365_S1 ( .D(in[1]), .E(n7), .CP(wr_clk), .CDN(n4), .Q(
        n152) );
  EDFCNQD1 clk1_r_REG366_S1 ( .D(in[1]), .E(n85), .CP(wr_clk), .CDN(n4), .Q(
        n151) );
  EDFCNQD1 clk1_r_REG367_S1 ( .D(in[1]), .E(n3), .CP(wr_clk), .CDN(n4), .Q(
        n150) );
  EDFCNQD1 clk1_r_REG368_S1 ( .D(in[1]), .E(n9), .CP(wr_clk), .CDN(n115), .Q(
        n149) );
  EDFCNQD1 clk1_r_REG369_S1 ( .D(in[1]), .E(n11), .CP(wr_clk), .CDN(n4), .Q(
        n148) );
  EDFCNQD1 clk1_r_REG370_S1 ( .D(in[1]), .E(n84), .CP(wr_clk), .CDN(n4), .Q(
        n147) );
  EDFCNQD1 clk1_r_REG371_S1 ( .D(in[1]), .E(n14), .CP(wr_clk), .CDN(n115), .Q(
        n146) );
  EDFCNQD1 clk1_r_REG372_S1 ( .D(in[0]), .E(n8), .CP(wr_clk), .CDN(n4), .Q(
        n145) );
  EDFCNQD1 clk1_r_REG373_S1 ( .D(in[0]), .E(n6), .CP(wr_clk), .CDN(n4), .Q(
        n144) );
  EDFCNQD1 clk1_r_REG374_S1 ( .D(in[0]), .E(n86), .CP(wr_clk), .CDN(n4), .Q(
        n143) );
  EDFCNQD1 clk1_r_REG375_S1 ( .D(in[0]), .E(n56), .CP(wr_clk), .CDN(n4), .Q(
        n142) );
  EDFCNQD1 clk1_r_REG376_S1 ( .D(in[0]), .E(n13), .CP(wr_clk), .CDN(n4), .Q(
        n141) );
  EDFCNQD1 clk1_r_REG377_S1 ( .D(in[0]), .E(n12), .CP(wr_clk), .CDN(n4), .Q(
        n140) );
  EDFCNQD1 clk1_r_REG378_S1 ( .D(in[0]), .E(n83), .CP(wr_clk), .CDN(n4), .Q(
        n139) );
  EDFCNQD1 clk1_r_REG379_S1 ( .D(in[0]), .E(n2), .CP(wr_clk), .CDN(n4), .Q(
        n138) );
  EDFCNQD1 clk1_r_REG380_S1 ( .D(in[0]), .E(n10), .CP(wr_clk), .CDN(n4), .Q(
        n137) );
  EDFCNQD1 clk1_r_REG381_S1 ( .D(in[0]), .E(n7), .CP(wr_clk), .CDN(n4), .Q(
        n136) );
  EDFCNQD1 clk1_r_REG382_S1 ( .D(in[0]), .E(n85), .CP(wr_clk), .CDN(n115), .Q(
        n135) );
  EDFCNQD1 clk1_r_REG383_S1 ( .D(in[0]), .E(n3), .CP(wr_clk), .CDN(n115), .Q(
        n134) );
  EDFCNQD1 clk1_r_REG384_S1 ( .D(in[0]), .E(n9), .CP(wr_clk), .CDN(n115), .Q(
        n133) );
  EDFCNQD1 clk1_r_REG385_S1 ( .D(in[0]), .E(n11), .CP(wr_clk), .CDN(n115), .Q(
        n132) );
  EDFCNQD1 clk1_r_REG386_S1 ( .D(in[0]), .E(n84), .CP(wr_clk), .CDN(n4), .Q(
        n131) );
  EDFCNQD1 clk1_r_REG387_S1 ( .D(in[0]), .E(n14), .CP(wr_clk), .CDN(n4), .Q(
        n130) );
  DFSNQD1 clk1_r_REG389_S1 ( .D(n612), .CP(wr_clk), .SDN(n115), .Q(n129) );
  DFSNQD1 clk1_r_REG390_S1 ( .D(n613), .CP(wr_clk), .SDN(n115), .Q(n128) );
  DFCNQD1 clk1_r_REG413_S1 ( .D(n104), .CP(wr_clk), .CDN(n115), .Q(n123) );
  DFCNQD1 clk1_r_REG414_S1 ( .D(n123), .CP(wr_clk), .CDN(n4), .Q(n122) );
  DFCNQD1 clk1_r_REG415_S1 ( .D(rd_ptr_gray[3]), .CP(wr_clk), .CDN(n4), .Q(
        n121) );
  DFCNQD1 clk1_r_REG416_S1 ( .D(n121), .CP(wr_clk), .CDN(n4), .Q(n120) );
  DFCNQD1 clk1_r_REG417_S1 ( .D(rd_ptr_gray[2]), .CP(wr_clk), .CDN(n115), .Q(
        n119) );
  DFCNQD1 clk1_r_REG418_S1 ( .D(rd_ptr_gray[1]), .CP(wr_clk), .CDN(n115), .Q(
        n118) );
  DFCNQD1 clk1_r_REG419_S1 ( .D(rd_ptr_gray[0]), .CP(wr_clk), .CDN(n4), .Q(
        n117) );
  DFCNQD1 clk1_r_REG420_S1 ( .D(n117), .CP(wr_clk), .CDN(n4), .Q(n116) );
  DFCNQD1 clk0_r_REG398_S1 ( .D(wr_ptr_gray_sync_rd2[0]), .CP(rd_clk), .CDN(n4), .Q(n114) );
  DFCNQD1 clk0_r_REG399_S1 ( .D(n114), .CP(rd_clk), .CDN(n115), .Q(n113) );
  DFCNQD1 clk0_r_REG400_S1 ( .D(wr_ptr_gray_sync_rd2[1]), .CP(rd_clk), .CDN(n4), .Q(n112) );
  DFCNQD1 clk0_r_REG401_S1 ( .D(n112), .CP(rd_clk), .CDN(n4), .Q(n111) );
  DFCNQD1 clk0_r_REG402_S1 ( .D(wr_ptr_gray_sync_rd2[2]), .CP(rd_clk), .CDN(
        n115), .Q(n110) );
  DFCNQD1 clk0_r_REG403_S1 ( .D(n110), .CP(rd_clk), .CDN(n115), .Q(n109) );
  DFCNQD1 clk0_r_REG404_S1 ( .D(wr_ptr_gray_sync_rd2[3]), .CP(rd_clk), .CDN(n4), .Q(n108) );
  DFCNQD1 clk0_r_REG405_S1 ( .D(n108), .CP(rd_clk), .CDN(n4), .Q(n107) );
  DFCNQD1 clk0_r_REG406_S1 ( .D(wr_ptr_gray_sync_rd1_4_), .CP(rd_clk), .CDN(
        n115), .Q(n106) );
  DFCNQD1 clk0_r_REG407_S1 ( .D(n106), .CP(rd_clk), .CDN(n4), .Q(n105) );
  EDFCNQD1 clk0_r_REG413_S1 ( .D(rd_ptr_gray[4]), .E(rd_fire), .CP(rd_clk), 
        .CDN(n4), .Q(n104) );
  EDFCNQD1 clk0_r_REG414_S1 ( .D(rd_ptr_bin[3]), .E(rd_fire), .CP(rd_clk), 
        .CDN(n115), .Q(n103) );
  EDFCNQD1 clk0_r_REG416_S1 ( .D(rd_ptr_bin[2]), .E(rd_fire), .CP(rd_clk), 
        .CDN(n115), .Q(n101) );
  EDFCNQD1 clk0_r_REG418_S1 ( .D(rd_ptr_bin[1]), .E(rd_fire), .CP(rd_clk), 
        .CDN(n115), .Q(n99) );
  EDFCNQD1 clk0_r_REG420_S1 ( .D(rd_ptr_bin[0]), .E(rd_fire), .CP(rd_clk), 
        .CDN(n115), .Q(n97) );
  DFSND1 clk0_r_REG415_S1 ( .D(n96), .CP(rd_clk), .SDN(n78), .Q(n102), .QN(n75) );
  DFSND1 clk0_r_REG417_S1 ( .D(n95), .CP(rd_clk), .SDN(n78), .Q(n100), .QN(n77) );
  DFSND1 clk0_r_REG419_S1 ( .D(n94), .CP(rd_clk), .SDN(n78), .Q(n98), .QN(n76)
         );
  EDFCNQD1 clk1_r_REG403_S1 ( .D(wr_ptr_bin_next[3]), .E(n79), .CP(wr_clk), 
        .CDN(n4), .Q(n127) );
  EDFCNQD1 clk1_r_REG402_S1 ( .D(wr_ptr_bin_next[4]), .E(n79), .CP(wr_clk), 
        .CDN(n115), .Q(wr_ptr_gray_sync_rd1_4_) );
  EDFCNQD1 clk1_r_REG388_S1 ( .D(wr_ptr_gray_next[0]), .E(n79), .CP(wr_clk), 
        .CDN(n4), .Q(wr_ptr_gray_sync_rd2[0]) );
  EDFCNQD1 clk1_r_REG391_S1 ( .D(wr_ptr_gray_next[1]), .E(n79), .CP(wr_clk), 
        .CDN(n4), .Q(wr_ptr_gray_sync_rd2[1]) );
  EDFCNQD1 clk1_r_REG392_S1 ( .D(wr_ptr_gray_next[2]), .E(n79), .CP(wr_clk), 
        .CDN(n115), .Q(wr_ptr_gray_sync_rd2[2]) );
  EDFCNQD1 clk1_r_REG393_S1 ( .D(wr_ptr_gray_next[3]), .E(n79), .CP(wr_clk), 
        .CDN(n4), .Q(wr_ptr_gray_sync_rd2[3]) );
  EDFCNQD1 clk1_r_REG404_S1 ( .D(wr_ptr_bin[2]), .E(n79), .CP(wr_clk), .CDN(
        n115), .Q(n126) );
  EDFCNQD1 clk1_r_REG406_S1 ( .D(wr_ptr_bin[0]), .E(n79), .CP(wr_clk), .CDN(
        n115), .Q(n124) );
  EDFCNQD2 clk1_r_REG405_S1 ( .D(wr_ptr_bin[1]), .E(n79), .CP(wr_clk), .CDN(
        n115), .Q(n125) );
  CKND3 U3 ( .I(reset), .ZN(n115) );
  CKND2D1 U4 ( .A1(n79), .A2(n58), .ZN(n28) );
  INVD0 U5 ( .I(n120), .ZN(n66) );
  AOI22D0 U6 ( .A1(wr_ptr_gray_next[1]), .A2(n128), .B1(wr_ptr_gray_next[2]), 
        .B2(n129), .ZN(n64) );
  OAI221D0 U7 ( .A1(n128), .A2(wr_ptr_gray_next[1]), .B1(n129), .B2(
        wr_ptr_gray_next[2]), .C(n64), .ZN(n616) );
  INVD0 U8 ( .I(n127), .ZN(n22) );
  INVD0 U9 ( .I(n125), .ZN(n42) );
  CKND2D0 U10 ( .A1(n22), .A2(n21), .ZN(n59) );
  INVD0 U11 ( .I(wr_ptr_bin[2]), .ZN(n62) );
  BUFFD3 U12 ( .I(n25), .Z(n86) );
  BUFFD2 U13 ( .I(n621), .Z(o_empty) );
  INVD6 U14 ( .I(n54), .ZN(n2) );
  INVD6 U15 ( .I(n55), .ZN(n3) );
  INVD0 U16 ( .I(n126), .ZN(n21) );
  CKBD6 U17 ( .I(n115), .Z(n4) );
  INVD0 U18 ( .I(wr), .ZN(n16) );
  CKND2D1 U19 ( .A1(n21), .A2(n127), .ZN(n52) );
  INVD6 U20 ( .I(n17), .ZN(n79) );
  NR2XD0 U21 ( .A1(n53), .A2(n49), .ZN(n50) );
  INVD2 U22 ( .I(n57), .ZN(n87) );
  INVD1 U23 ( .I(n103), .ZN(n57) );
  NR2D0 U24 ( .A1(n125), .A2(n124), .ZN(n58) );
  BUFFD3 U25 ( .I(n50), .Z(n14) );
  OR2D1 U26 ( .A1(n53), .A2(n52), .Z(n55) );
  OR2D1 U27 ( .A1(n53), .A2(n59), .Z(n54) );
  CKND2D1 U28 ( .A1(n127), .A2(n126), .ZN(n51) );
  BUFFD4 U29 ( .I(n43), .Z(n6) );
  BUFFD4 U30 ( .I(n45), .Z(n7) );
  BUFFD4 U31 ( .I(n32), .Z(n8) );
  BUFFD4 U32 ( .I(n27), .Z(n9) );
  BUFFD4 U33 ( .I(n26), .Z(n10) );
  BUFFD4 U34 ( .I(n47), .Z(n11) );
  BUFFD4 U35 ( .I(n46), .Z(n12) );
  INVD2 U36 ( .I(n65), .ZN(n13) );
  CKND2 U37 ( .I(n48), .ZN(n17) );
  NR2XD1 U38 ( .A1(n1), .A2(n16), .ZN(n48) );
  CKND2D1 U39 ( .A1(n22), .A2(n126), .ZN(n49) );
  INVD1 U40 ( .I(n124), .ZN(n71) );
  ND3D1 U41 ( .A1(n48), .A2(n124), .A3(n125), .ZN(n53) );
  OR2D1 U42 ( .A1(n53), .A2(n51), .Z(n15) );
  INVD4 U43 ( .I(n15), .ZN(n56) );
  INVD0 U44 ( .I(wr_ptr_bin_next[3]), .ZN(n63) );
  BUFFD3 U45 ( .I(n19), .Z(n84) );
  BUFFD3 U46 ( .I(n18), .Z(n85) );
  BUFFD3 U47 ( .I(n23), .Z(n83) );
  INVD0 U48 ( .I(n58), .ZN(n60) );
  INVD0 U49 ( .I(n111), .ZN(n35) );
  INVD0 U50 ( .I(n109), .ZN(n34) );
  AOI22D0 U51 ( .A1(rd_ptr_gray[3]), .A2(n41), .B1(n104), .B2(n37), .ZN(n36)
         );
  INVD0 U52 ( .I(n107), .ZN(n41) );
  INVD0 U53 ( .I(n105), .ZN(n37) );
  NR2D0 U54 ( .A1(n60), .A2(n59), .ZN(N17) );
  AOI22D0 U55 ( .A1(rd_ptr_gray[1]), .A2(n35), .B1(rd_ptr_gray[2]), .B2(n34), 
        .ZN(n33) );
  INVD0 U56 ( .I(rd_ptr_gray[0]), .ZN(n70) );
  INVD0 U57 ( .I(rd_ptr_bin[1]), .ZN(n72) );
  INR2D1 U58 ( .A1(rd), .B1(o_empty), .ZN(rd_fire) );
  TIEL U59 ( .ZN(n514) );
  CKXOR2D1 U60 ( .A1(wr_ptr_bin_next[4]), .A2(wr_ptr_bin_next[3]), .Z(
        wr_ptr_gray_next[3]) );
  ND3D2 U62 ( .A1(n79), .A2(n125), .A3(n71), .ZN(n24) );
  NR2D1 U63 ( .A1(n24), .A2(n52), .ZN(n18) );
  NR2D1 U64 ( .A1(n24), .A2(n49), .ZN(n19) );
  NR2D1 U65 ( .A1(n24), .A2(n59), .ZN(n23) );
  NR2D1 U66 ( .A1(n24), .A2(n51), .ZN(n25) );
  BUFFD2 U67 ( .I(n97), .Z(n91) );
  NR2D1 U68 ( .A1(n28), .A2(n52), .ZN(n26) );
  NR2D1 U69 ( .A1(n28), .A2(n49), .ZN(n27) );
  NR2D1 U70 ( .A1(n28), .A2(n51), .ZN(n32) );
  INVD1 U72 ( .I(n101), .ZN(n61) );
  INVD1 U73 ( .I(n99), .ZN(n69) );
  MUX2ND0 U74 ( .I0(n100), .I1(n61), .S(n69), .ZN(rd_ptr_gray[1]) );
  MUX2ND0 U75 ( .I0(n102), .I1(n57), .S(n61), .ZN(rd_ptr_gray[2]) );
  OAI221D0 U76 ( .A1(n35), .A2(rd_ptr_gray[1]), .B1(n34), .B2(rd_ptr_gray[2]), 
        .C(n33), .ZN(n619) );
  MUX2ND0 U77 ( .I0(n57), .I1(n102), .S(n104), .ZN(rd_ptr_gray[3]) );
  OAI221D0 U78 ( .A1(n41), .A2(rd_ptr_gray[3]), .B1(n37), .B2(n104), .C(n36), 
        .ZN(n618) );
  CKBD1 U79 ( .I(n97), .Z(n92) );
  ND3D2 U80 ( .A1(n79), .A2(n124), .A3(n42), .ZN(n44) );
  NR2D1 U81 ( .A1(n44), .A2(n51), .ZN(n43) );
  NR2D1 U82 ( .A1(n44), .A2(n52), .ZN(n45) );
  NR2D1 U83 ( .A1(n44), .A2(n59), .ZN(n46) );
  NR2D1 U84 ( .A1(n44), .A2(n49), .ZN(n47) );
  CKBD1 U85 ( .I(n97), .Z(n93) );
  INVD0 U86 ( .I(n79), .ZN(n620) );
  INVD0 U88 ( .I(n119), .ZN(n612) );
  INVD0 U89 ( .I(n118), .ZN(n613) );
  INVD1 U90 ( .I(n69), .ZN(n90) );
  INVD1 U91 ( .I(n61), .ZN(n88) );
  INVD2 U92 ( .I(n69), .ZN(n89) );
  MUX2ND0 U93 ( .I0(n62), .I1(wr_ptr_bin[2]), .S(wr_ptr_bin[1]), .ZN(
        wr_ptr_gray_next[1]) );
  MUX2ND0 U94 ( .I0(wr_ptr_bin_next[3]), .I1(n63), .S(n62), .ZN(
        wr_ptr_gray_next[2]) );
  INVD1 U95 ( .I(N48), .ZN(n65) );
  INVD1 U96 ( .I(n65), .ZN(n82) );
  INVD1 U97 ( .I(n65), .ZN(n81) );
  INVD1 U98 ( .I(n65), .ZN(n80) );
  XNR2D1 U99 ( .A1(wr_ptr_gray_next[3]), .A2(n66), .ZN(n68) );
  CKXOR2D1 U100 ( .A1(wr_ptr_bin_next[4]), .A2(n122), .Z(n67) );
  ND2D1 U101 ( .A1(n68), .A2(n67), .ZN(n615) );
  MUX2ND0 U102 ( .I0(n69), .I1(n98), .S(n97), .ZN(rd_ptr_gray[0]) );
  MUX2ND0 U103 ( .I0(n70), .I1(rd_ptr_gray[0]), .S(n113), .ZN(n617) );
  INVD0 U104 ( .I(reset), .ZN(n78) );
  CKXOR2D1 U105 ( .A1(wr_ptr_bin[1]), .A2(n71), .Z(wr_ptr_gray_next[0]) );
  CKXOR2D1 U106 ( .A1(wr_ptr_gray_next[0]), .A2(n116), .Z(n614) );
  MUX2ND0 U107 ( .I0(n76), .I1(n72), .S(rd_fire), .ZN(n94) );
  INVD0 U108 ( .I(rd_ptr_bin[2]), .ZN(n73) );
  MUX2ND0 U109 ( .I0(n77), .I1(n73), .S(rd_fire), .ZN(n95) );
  INVD0 U110 ( .I(rd_ptr_bin[3]), .ZN(n74) );
  MUX2ND0 U111 ( .I0(n75), .I1(n74), .S(rd_fire), .ZN(n96) );
  MUX4ND0 U112 ( .I0(n141), .I1(n140), .I2(n139), .I3(n138), .S0(n91), .S1(n89), .ZN(n516) );
  MUX4ND0 U113 ( .I0(n137), .I1(n136), .I2(n135), .I3(n134), .S0(n91), .S1(n89), .ZN(n517) );
  MUX4ND0 U114 ( .I0(n133), .I1(n132), .I2(n131), .I3(n130), .S0(n92), .S1(n89), .ZN(n518) );
  MUX4ND0 U115 ( .I0(n145), .I1(n144), .I2(n143), .I3(n142), .S0(n91), .S1(n89), .ZN(n519) );
  MUX4ND0 U116 ( .I0(n516), .I1(n517), .I2(n518), .I3(n519), .S0(n87), .S1(n88), .ZN(out[0]) );
  MUX4ND0 U117 ( .I0(n157), .I1(n156), .I2(n155), .I3(n154), .S0(n92), .S1(n89), .ZN(n520) );
  MUX4ND0 U118 ( .I0(n153), .I1(n152), .I2(n151), .I3(n150), .S0(n92), .S1(n89), .ZN(n521) );
  MUX4ND0 U119 ( .I0(n149), .I1(n148), .I2(n147), .I3(n146), .S0(n92), .S1(n89), .ZN(n522) );
  MUX4ND0 U120 ( .I0(n161), .I1(n160), .I2(n159), .I3(n158), .S0(n92), .S1(n89), .ZN(n523) );
  MUX4ND0 U121 ( .I0(n520), .I1(n521), .I2(n522), .I3(n523), .S0(n87), .S1(n88), .ZN(out[1]) );
  MUX4ND0 U122 ( .I0(n173), .I1(n172), .I2(n171), .I3(n170), .S0(n91), .S1(n89), .ZN(n524) );
  MUX4ND0 U123 ( .I0(n169), .I1(n168), .I2(n167), .I3(n166), .S0(n91), .S1(n89), .ZN(n525) );
  MUX4ND0 U124 ( .I0(n165), .I1(n164), .I2(n163), .I3(n162), .S0(n92), .S1(n89), .ZN(n526) );
  MUX4ND0 U125 ( .I0(n177), .I1(n176), .I2(n175), .I3(n174), .S0(n91), .S1(n89), .ZN(n527) );
  MUX4ND0 U126 ( .I0(n524), .I1(n525), .I2(n526), .I3(n527), .S0(n87), .S1(n88), .ZN(out[2]) );
  MUX4ND0 U127 ( .I0(n189), .I1(n188), .I2(n187), .I3(n186), .S0(n91), .S1(n89), .ZN(n528) );
  MUX4ND0 U128 ( .I0(n185), .I1(n184), .I2(n183), .I3(n182), .S0(n91), .S1(n89), .ZN(n529) );
  MUX4ND0 U129 ( .I0(n181), .I1(n180), .I2(n179), .I3(n178), .S0(n91), .S1(n89), .ZN(n530) );
  MUX4ND0 U130 ( .I0(n193), .I1(n192), .I2(n191), .I3(n190), .S0(n91), .S1(n89), .ZN(n531) );
  MUX4ND0 U131 ( .I0(n528), .I1(n529), .I2(n530), .I3(n531), .S0(n87), .S1(n88), .ZN(out[3]) );
  MUX4ND0 U132 ( .I0(n205), .I1(n204), .I2(n203), .I3(n202), .S0(n91), .S1(n89), .ZN(n532) );
  MUX4ND0 U133 ( .I0(n201), .I1(n200), .I2(n199), .I3(n198), .S0(n91), .S1(n89), .ZN(n533) );
  MUX4ND0 U134 ( .I0(n197), .I1(n196), .I2(n195), .I3(n194), .S0(n91), .S1(n89), .ZN(n534) );
  MUX4ND0 U135 ( .I0(n209), .I1(n208), .I2(n207), .I3(n206), .S0(n91), .S1(n89), .ZN(n535) );
  MUX4ND0 U136 ( .I0(n532), .I1(n533), .I2(n534), .I3(n535), .S0(n87), .S1(n88), .ZN(out[4]) );
  MUX4ND0 U137 ( .I0(n221), .I1(n220), .I2(n219), .I3(n218), .S0(n91), .S1(n89), .ZN(n536) );
  MUX4ND0 U138 ( .I0(n217), .I1(n216), .I2(n215), .I3(n214), .S0(n91), .S1(n89), .ZN(n537) );
  MUX4ND0 U139 ( .I0(n213), .I1(n212), .I2(n211), .I3(n210), .S0(n91), .S1(n89), .ZN(n538) );
  MUX4ND0 U140 ( .I0(n225), .I1(n224), .I2(n223), .I3(n222), .S0(n91), .S1(n89), .ZN(n539) );
  MUX4ND0 U141 ( .I0(n536), .I1(n537), .I2(n538), .I3(n539), .S0(n87), .S1(n88), .ZN(out[5]) );
  MUX4ND0 U142 ( .I0(n237), .I1(n236), .I2(n235), .I3(n234), .S0(n91), .S1(n89), .ZN(n540) );
  MUX4ND0 U143 ( .I0(n233), .I1(n232), .I2(n231), .I3(n230), .S0(n93), .S1(n89), .ZN(n541) );
  MUX4ND0 U144 ( .I0(n229), .I1(n228), .I2(n227), .I3(n226), .S0(n93), .S1(n89), .ZN(n542) );
  MUX4ND0 U145 ( .I0(n241), .I1(n240), .I2(n239), .I3(n238), .S0(n93), .S1(n89), .ZN(n543) );
  MUX4ND0 U146 ( .I0(n540), .I1(n541), .I2(n542), .I3(n543), .S0(n87), .S1(n88), .ZN(out[6]) );
  MUX4ND0 U147 ( .I0(n253), .I1(n252), .I2(n251), .I3(n250), .S0(n93), .S1(n89), .ZN(n544) );
  MUX4ND0 U148 ( .I0(n249), .I1(n248), .I2(n247), .I3(n246), .S0(n93), .S1(n89), .ZN(n545) );
  MUX4ND0 U149 ( .I0(n245), .I1(n244), .I2(n243), .I3(n242), .S0(n93), .S1(n89), .ZN(n546) );
  MUX4ND0 U150 ( .I0(n257), .I1(n256), .I2(n255), .I3(n254), .S0(n93), .S1(n89), .ZN(n547) );
  MUX4ND0 U151 ( .I0(n544), .I1(n545), .I2(n546), .I3(n547), .S0(n87), .S1(n88), .ZN(out[7]) );
  MUX4ND0 U152 ( .I0(n269), .I1(n268), .I2(n267), .I3(n266), .S0(n93), .S1(n89), .ZN(n548) );
  MUX4ND0 U153 ( .I0(n265), .I1(n264), .I2(n263), .I3(n262), .S0(n93), .S1(n89), .ZN(n549) );
  MUX4ND0 U154 ( .I0(n261), .I1(n260), .I2(n259), .I3(n258), .S0(n93), .S1(n89), .ZN(n550) );
  MUX4ND0 U155 ( .I0(n273), .I1(n272), .I2(n271), .I3(n270), .S0(n93), .S1(n89), .ZN(n551) );
  MUX4ND0 U156 ( .I0(n548), .I1(n549), .I2(n550), .I3(n551), .S0(n87), .S1(n88), .ZN(out[8]) );
  MUX4ND0 U157 ( .I0(n285), .I1(n284), .I2(n283), .I3(n282), .S0(n93), .S1(n89), .ZN(n552) );
  MUX4ND0 U158 ( .I0(n281), .I1(n280), .I2(n279), .I3(n278), .S0(n93), .S1(n89), .ZN(n553) );
  MUX4ND0 U159 ( .I0(n277), .I1(n276), .I2(n275), .I3(n274), .S0(n93), .S1(n89), .ZN(n554) );
  MUX4ND0 U160 ( .I0(n289), .I1(n288), .I2(n287), .I3(n286), .S0(n93), .S1(n89), .ZN(n555) );
  MUX4ND0 U161 ( .I0(n552), .I1(n553), .I2(n554), .I3(n555), .S0(n87), .S1(n88), .ZN(out[9]) );
  MUX4ND0 U162 ( .I0(n301), .I1(n300), .I2(n299), .I3(n298), .S0(n92), .S1(n89), .ZN(n556) );
  MUX4ND0 U163 ( .I0(n297), .I1(n296), .I2(n295), .I3(n294), .S0(n92), .S1(n89), .ZN(n557) );
  MUX4ND0 U164 ( .I0(n293), .I1(n292), .I2(n291), .I3(n290), .S0(n92), .S1(n89), .ZN(n558) );
  MUX4ND0 U165 ( .I0(n305), .I1(n304), .I2(n303), .I3(n302), .S0(n92), .S1(n89), .ZN(n559) );
  MUX4ND0 U166 ( .I0(n556), .I1(n557), .I2(n558), .I3(n559), .S0(n87), .S1(n88), .ZN(out[10]) );
  MUX4ND0 U167 ( .I0(n317), .I1(n316), .I2(n315), .I3(n314), .S0(n93), .S1(n89), .ZN(n560) );
  MUX4ND0 U168 ( .I0(n313), .I1(n312), .I2(n311), .I3(n310), .S0(n93), .S1(n89), .ZN(n561) );
  MUX4ND0 U169 ( .I0(n309), .I1(n308), .I2(n307), .I3(n306), .S0(n93), .S1(n89), .ZN(n562) );
  MUX4ND0 U170 ( .I0(n321), .I1(n320), .I2(n319), .I3(n318), .S0(n93), .S1(n89), .ZN(n563) );
  MUX4ND0 U171 ( .I0(n560), .I1(n561), .I2(n562), .I3(n563), .S0(n87), .S1(n88), .ZN(out[11]) );
  MUX4ND0 U172 ( .I0(n333), .I1(n332), .I2(n331), .I3(n330), .S0(n92), .S1(n89), .ZN(n564) );
  MUX4ND0 U173 ( .I0(n329), .I1(n328), .I2(n327), .I3(n326), .S0(n92), .S1(n89), .ZN(n565) );
  MUX4ND0 U174 ( .I0(n325), .I1(n324), .I2(n323), .I3(n322), .S0(n92), .S1(n89), .ZN(n566) );
  MUX4ND0 U175 ( .I0(n337), .I1(n336), .I2(n335), .I3(n334), .S0(n92), .S1(n89), .ZN(n567) );
  MUX4ND0 U176 ( .I0(n564), .I1(n565), .I2(n566), .I3(n567), .S0(n87), .S1(n88), .ZN(out[12]) );
  MUX4ND0 U177 ( .I0(n349), .I1(n348), .I2(n347), .I3(n346), .S0(n92), .S1(n89), .ZN(n568) );
  MUX4ND0 U178 ( .I0(n345), .I1(n344), .I2(n343), .I3(n342), .S0(n92), .S1(n89), .ZN(n569) );
  MUX4ND0 U179 ( .I0(n341), .I1(n340), .I2(n339), .I3(n338), .S0(n92), .S1(n89), .ZN(n570) );
  MUX4ND0 U180 ( .I0(n353), .I1(n352), .I2(n351), .I3(n350), .S0(n92), .S1(n89), .ZN(n571) );
  MUX4ND0 U181 ( .I0(n568), .I1(n569), .I2(n570), .I3(n571), .S0(n87), .S1(n88), .ZN(out[13]) );
  MUX4ND0 U182 ( .I0(n365), .I1(n364), .I2(n363), .I3(n362), .S0(n92), .S1(n89), .ZN(n572) );
  MUX4ND0 U183 ( .I0(n361), .I1(n360), .I2(n359), .I3(n358), .S0(n92), .S1(n89), .ZN(n573) );
  MUX4ND0 U184 ( .I0(n357), .I1(n356), .I2(n355), .I3(n354), .S0(n92), .S1(n89), .ZN(n574) );
  MUX4ND0 U185 ( .I0(n369), .I1(n368), .I2(n367), .I3(n366), .S0(n92), .S1(n89), .ZN(n575) );
  MUX4ND0 U186 ( .I0(n572), .I1(n573), .I2(n574), .I3(n575), .S0(n87), .S1(n88), .ZN(out[14]) );
  MUX4ND0 U187 ( .I0(n381), .I1(n380), .I2(n379), .I3(n378), .S0(n92), .S1(n89), .ZN(n576) );
  MUX4ND0 U188 ( .I0(n377), .I1(n376), .I2(n375), .I3(n374), .S0(n92), .S1(n89), .ZN(n577) );
  MUX4ND0 U189 ( .I0(n373), .I1(n372), .I2(n371), .I3(n370), .S0(n92), .S1(n89), .ZN(n578) );
  MUX4ND0 U190 ( .I0(n385), .I1(n384), .I2(n383), .I3(n382), .S0(n92), .S1(n89), .ZN(n579) );
  MUX4ND0 U191 ( .I0(n576), .I1(n577), .I2(n578), .I3(n579), .S0(n87), .S1(n88), .ZN(out[15]) );
  MUX4ND0 U192 ( .I0(n397), .I1(n396), .I2(n395), .I3(n394), .S0(n91), .S1(n89), .ZN(n580) );
  MUX4ND0 U193 ( .I0(n393), .I1(n392), .I2(n391), .I3(n390), .S0(n91), .S1(n89), .ZN(n581) );
  MUX4ND0 U194 ( .I0(n389), .I1(n388), .I2(n387), .I3(n386), .S0(n91), .S1(n89), .ZN(n582) );
  MUX4ND0 U195 ( .I0(n401), .I1(n400), .I2(n399), .I3(n398), .S0(n91), .S1(n89), .ZN(n583) );
  MUX4ND0 U196 ( .I0(n580), .I1(n581), .I2(n582), .I3(n583), .S0(n87), .S1(n88), .ZN(out[16]) );
  MUX4ND0 U197 ( .I0(n413), .I1(n412), .I2(n411), .I3(n410), .S0(n91), .S1(n89), .ZN(n584) );
  MUX4ND0 U198 ( .I0(n409), .I1(n408), .I2(n407), .I3(n406), .S0(n91), .S1(n89), .ZN(n585) );
  MUX4ND0 U199 ( .I0(n405), .I1(n404), .I2(n403), .I3(n402), .S0(n91), .S1(n90), .ZN(n586) );
  MUX4ND0 U200 ( .I0(n417), .I1(n416), .I2(n415), .I3(n414), .S0(n91), .S1(n90), .ZN(n587) );
  MUX4ND0 U201 ( .I0(n584), .I1(n585), .I2(n586), .I3(n587), .S0(n87), .S1(n88), .ZN(out[17]) );
  MUX4ND0 U202 ( .I0(n429), .I1(n428), .I2(n427), .I3(n426), .S0(n91), .S1(n90), .ZN(n588) );
  MUX4ND0 U203 ( .I0(n425), .I1(n424), .I2(n423), .I3(n422), .S0(n91), .S1(n90), .ZN(n589) );
  MUX4ND0 U204 ( .I0(n421), .I1(n420), .I2(n419), .I3(n418), .S0(n91), .S1(n90), .ZN(n590) );
  MUX4ND0 U205 ( .I0(n433), .I1(n432), .I2(n431), .I3(n430), .S0(n91), .S1(n90), .ZN(n591) );
  MUX4ND0 U206 ( .I0(n588), .I1(n589), .I2(n590), .I3(n591), .S0(n87), .S1(n88), .ZN(out[18]) );
  MUX4ND0 U207 ( .I0(n445), .I1(n444), .I2(n443), .I3(n442), .S0(n91), .S1(n90), .ZN(n592) );
  MUX4ND0 U208 ( .I0(n441), .I1(n440), .I2(n439), .I3(n438), .S0(n91), .S1(n90), .ZN(n593) );
  MUX4ND0 U209 ( .I0(n437), .I1(n436), .I2(n435), .I3(n434), .S0(n91), .S1(n90), .ZN(n594) );
  MUX4ND0 U210 ( .I0(n449), .I1(n448), .I2(n447), .I3(n446), .S0(n91), .S1(n90), .ZN(n595) );
  MUX4ND0 U211 ( .I0(n592), .I1(n593), .I2(n594), .I3(n595), .S0(n87), .S1(n88), .ZN(out[19]) );
  MUX4ND0 U212 ( .I0(n461), .I1(n460), .I2(n459), .I3(n458), .S0(n91), .S1(n90), .ZN(n596) );
  MUX4ND0 U213 ( .I0(n457), .I1(n456), .I2(n455), .I3(n454), .S0(n91), .S1(n90), .ZN(n597) );
  MUX4ND0 U214 ( .I0(n453), .I1(n452), .I2(n451), .I3(n450), .S0(n91), .S1(n90), .ZN(n598) );
  MUX4ND0 U215 ( .I0(n465), .I1(n464), .I2(n463), .I3(n462), .S0(n91), .S1(n90), .ZN(n599) );
  MUX4ND0 U216 ( .I0(n596), .I1(n597), .I2(n598), .I3(n599), .S0(n87), .S1(n88), .ZN(out[20]) );
  MUX4ND0 U217 ( .I0(n477), .I1(n476), .I2(n475), .I3(n474), .S0(n91), .S1(n90), .ZN(n600) );
  MUX4ND0 U218 ( .I0(n473), .I1(n472), .I2(n471), .I3(n470), .S0(n91), .S1(n90), .ZN(n601) );
  MUX4ND0 U219 ( .I0(n469), .I1(n468), .I2(n467), .I3(n466), .S0(n91), .S1(n90), .ZN(n602) );
  MUX4ND0 U220 ( .I0(n481), .I1(n480), .I2(n479), .I3(n478), .S0(n91), .S1(n90), .ZN(n603) );
  MUX4ND0 U221 ( .I0(n600), .I1(n601), .I2(n602), .I3(n603), .S0(n87), .S1(n88), .ZN(out[21]) );
  MUX4ND0 U222 ( .I0(n493), .I1(n492), .I2(n491), .I3(n490), .S0(n91), .S1(n90), .ZN(n604) );
  MUX4ND0 U223 ( .I0(n489), .I1(n488), .I2(n487), .I3(n486), .S0(n91), .S1(n90), .ZN(n605) );
  MUX4ND0 U224 ( .I0(n485), .I1(n484), .I2(n483), .I3(n482), .S0(n93), .S1(n90), .ZN(n606) );
  MUX4ND0 U225 ( .I0(n497), .I1(n496), .I2(n495), .I3(n494), .S0(n93), .S1(n90), .ZN(n607) );
  MUX4ND0 U226 ( .I0(n604), .I1(n605), .I2(n606), .I3(n607), .S0(n87), .S1(n88), .ZN(out[22]) );
  MUX4ND0 U227 ( .I0(n509), .I1(n508), .I2(n507), .I3(n506), .S0(n93), .S1(n90), .ZN(n608) );
  MUX4ND0 U228 ( .I0(n505), .I1(n504), .I2(n503), .I3(n502), .S0(n93), .S1(n90), .ZN(n609) );
  MUX4ND0 U229 ( .I0(n501), .I1(n500), .I2(n499), .I3(n498), .S0(n93), .S1(n90), .ZN(n610) );
  MUX4ND0 U230 ( .I0(n513), .I1(n512), .I2(n511), .I3(n510), .S0(n93), .S1(n90), .ZN(n611) );
  MUX4ND0 U231 ( .I0(n608), .I1(n609), .I2(n610), .I3(n611), .S0(n87), .S1(n88), .ZN(out[23]) );
endmodule


module fullchip ( clk0, clk1, mem_in0, mem_in1, inst0, inst1, reset0, reset1, 
        out0, out1, fifo0_empty, fifo1_empty );
  input [63:0] mem_in0;
  input [63:0] mem_in1;
  input [19:0] inst0;
  input [19:0] inst1;
  output [159:0] out0;
  output [159:0] out1;
  input clk0, clk1, reset0, reset1;
  output fifo0_empty, fifo1_empty;
  wire   n1, n3, n5, n6, n7, n8, n9, n10, n11, n12, n13, n14, n15, n16, n17,
         n18, n19, n20, n21, n22, n23, n24, n25, n26, n27, n28, n29, n30, n31,
         n32, n33, n34, n35, n36, n37, n38, n39, n40, n41, n42, n43, n44, n45,
         n46, n47, n48, n49, n50, n51, n52, n53, n54, n55, n56, n57, n58, n59,
         n60, n61, n62, n63, n64, n65, n66, n67, n68, n69, n70, n71, n72, n73,
         n74, n75, n76, n77;
  wire   [23:0] sum_out_1_0;
  wire   [23:0] sum_out_0_1;
  tri   clk0;
  tri   clk1;
  tri   [63:0] mem_in0;
  tri   [63:0] mem_in1;
  tri   [19:0] inst0;
  tri   [19:0] inst1;
  tri   reset0;
  tri   reset1;
  tri   [159:0] out0;
  tri   [159:0] out1;
  tri   [23:0] sfp_sum_in_0_r;
  tri   [23:0] sfp_sum_in_1_r;
  tri   fifo_wr_core0;
  tri   [23:0] ext_fifo_in_0;
  tri   fifo_rd_core0;
  tri   fifo_wr_core1;
  tri   [23:0] ext_fifo_in_1;
  tri   fifo_rd_core1;

  core core_instance_0 ( .clk(clk0), .sum_in(sfp_sum_in_0_r), .mem_in(mem_in0), 
        .out(out0), .inst(inst0), .reset(reset0), .ext_fifo_wr(fifo_wr_core0), 
        .ext_fifo_in(ext_fifo_in_0), .ext_fifo_rd(fifo_rd_core0) );
  core core_instance_1 ( .clk(clk1), .sum_in(sfp_sum_in_1_r), .mem_in(mem_in1), 
        .out(out1), .inst(inst1), .reset(reset1), .ext_fifo_wr(fifo_wr_core1), 
        .ext_fifo_in(ext_fifo_in_1), .ext_fifo_rd(fifo_rd_core1) );
  fifo_depth16_async_bw24_2 fifo_inst_ext_core0_1 ( .rd_clk(clk1), .wr_clk(
        clk0), .rd(fifo_rd_core1), .wr(fifo_wr_core0), .reset(reset0), .in(
        ext_fifo_in_0), .out(sum_out_0_1), .o_empty(fifo0_empty) );
  fifo_depth16_async_bw24_3 fifo_inst_ext_core1_0 ( .rd_clk(clk0), .wr_clk(
        clk1), .rd(fifo_rd_core0), .wr(fifo_wr_core1), .reset(reset1), .in(
        ext_fifo_in_1), .out(sum_out_1_0), .o_empty(fifo1_empty) );
  AO22D0 U5 ( .A1(n77), .A2(sfp_sum_in_0_r[0]), .B1(n1), .B2(sum_out_1_0[0]), 
        .Z(n5) );
  AO22D0 U6 ( .A1(n77), .A2(sfp_sum_in_0_r[1]), .B1(n1), .B2(sum_out_1_0[1]), 
        .Z(n6) );
  AO22D0 U7 ( .A1(n77), .A2(sfp_sum_in_0_r[2]), .B1(n1), .B2(sum_out_1_0[2]), 
        .Z(n7) );
  AO22D0 U8 ( .A1(n77), .A2(sfp_sum_in_0_r[3]), .B1(n1), .B2(sum_out_1_0[3]), 
        .Z(n8) );
  AO22D0 U9 ( .A1(n77), .A2(sfp_sum_in_0_r[4]), .B1(n1), .B2(sum_out_1_0[4]), 
        .Z(n9) );
  AO22D0 U10 ( .A1(n77), .A2(sfp_sum_in_0_r[5]), .B1(n1), .B2(sum_out_1_0[5]), 
        .Z(n10) );
  AO22D0 U11 ( .A1(n77), .A2(sfp_sum_in_0_r[6]), .B1(n1), .B2(sum_out_1_0[6]), 
        .Z(n11) );
  AO22D0 U12 ( .A1(n77), .A2(sfp_sum_in_0_r[7]), .B1(n1), .B2(sum_out_1_0[7]), 
        .Z(n12) );
  AO22D0 U13 ( .A1(n77), .A2(sfp_sum_in_0_r[8]), .B1(n1), .B2(sum_out_1_0[8]), 
        .Z(n13) );
  AO22D0 U14 ( .A1(n77), .A2(sfp_sum_in_0_r[9]), .B1(n1), .B2(sum_out_1_0[9]), 
        .Z(n14) );
  AO22D0 U15 ( .A1(n77), .A2(sfp_sum_in_0_r[10]), .B1(n1), .B2(sum_out_1_0[10]), .Z(n15) );
  AO22D0 U16 ( .A1(n77), .A2(sfp_sum_in_0_r[11]), .B1(n1), .B2(sum_out_1_0[11]), .Z(n16) );
  AO22D0 U17 ( .A1(n77), .A2(sfp_sum_in_0_r[12]), .B1(n1), .B2(sum_out_1_0[12]), .Z(n17) );
  AO22D0 U18 ( .A1(n77), .A2(sfp_sum_in_0_r[13]), .B1(n1), .B2(sum_out_1_0[13]), .Z(n18) );
  AO22D0 U19 ( .A1(n77), .A2(sfp_sum_in_0_r[14]), .B1(n1), .B2(sum_out_1_0[14]), .Z(n19) );
  AO22D0 U20 ( .A1(n77), .A2(sfp_sum_in_0_r[15]), .B1(n1), .B2(sum_out_1_0[15]), .Z(n20) );
  AO22D0 U21 ( .A1(n77), .A2(sfp_sum_in_0_r[16]), .B1(n1), .B2(sum_out_1_0[16]), .Z(n21) );
  AO22D0 U22 ( .A1(n77), .A2(sfp_sum_in_0_r[17]), .B1(n1), .B2(sum_out_1_0[17]), .Z(n22) );
  AO22D0 U23 ( .A1(n77), .A2(sfp_sum_in_0_r[18]), .B1(n1), .B2(sum_out_1_0[18]), .Z(n23) );
  AO22D0 U24 ( .A1(n77), .A2(sfp_sum_in_0_r[19]), .B1(n1), .B2(sum_out_1_0[19]), .Z(n24) );
  AO22D0 U25 ( .A1(n77), .A2(sfp_sum_in_0_r[20]), .B1(n1), .B2(sum_out_1_0[20]), .Z(n25) );
  AO22D0 U26 ( .A1(n77), .A2(sfp_sum_in_0_r[21]), .B1(n1), .B2(sum_out_1_0[21]), .Z(n26) );
  AO22D0 U27 ( .A1(n77), .A2(sfp_sum_in_0_r[22]), .B1(n1), .B2(sum_out_1_0[22]), .Z(n27) );
  AO22D0 U28 ( .A1(n77), .A2(sfp_sum_in_0_r[23]), .B1(n1), .B2(sum_out_1_0[23]), .Z(n28) );
  AO22D0 U53 ( .A1(n76), .A2(sfp_sum_in_1_r[22]), .B1(n3), .B2(sum_out_0_1[22]), .Z(n51) );
  AO22D0 U54 ( .A1(n76), .A2(sfp_sum_in_1_r[23]), .B1(n3), .B2(sum_out_0_1[23]), .Z(n52) );
  DFQD1 sfp_sum_in_0_r_reg_23_ ( .D(n28), .CP(clk0), .Q(sfp_sum_in_0_r[23]) );
  DFQD1 sfp_sum_in_0_r_reg_22_ ( .D(n27), .CP(clk0), .Q(sfp_sum_in_0_r[22]) );
  DFQD1 sfp_sum_in_0_r_reg_21_ ( .D(n26), .CP(clk0), .Q(sfp_sum_in_0_r[21]) );
  DFQD1 sfp_sum_in_0_r_reg_20_ ( .D(n25), .CP(clk0), .Q(sfp_sum_in_0_r[20]) );
  DFQD1 sfp_sum_in_0_r_reg_19_ ( .D(n24), .CP(clk0), .Q(sfp_sum_in_0_r[19]) );
  DFQD1 sfp_sum_in_0_r_reg_18_ ( .D(n23), .CP(clk0), .Q(sfp_sum_in_0_r[18]) );
  DFQD1 sfp_sum_in_0_r_reg_17_ ( .D(n22), .CP(clk0), .Q(sfp_sum_in_0_r[17]) );
  DFQD1 sfp_sum_in_0_r_reg_16_ ( .D(n21), .CP(clk0), .Q(sfp_sum_in_0_r[16]) );
  DFQD1 sfp_sum_in_0_r_reg_15_ ( .D(n20), .CP(clk0), .Q(sfp_sum_in_0_r[15]) );
  DFQD1 sfp_sum_in_0_r_reg_14_ ( .D(n19), .CP(clk0), .Q(sfp_sum_in_0_r[14]) );
  DFQD1 sfp_sum_in_0_r_reg_13_ ( .D(n18), .CP(clk0), .Q(sfp_sum_in_0_r[13]) );
  DFQD1 sfp_sum_in_0_r_reg_12_ ( .D(n17), .CP(clk0), .Q(sfp_sum_in_0_r[12]) );
  DFQD1 sfp_sum_in_0_r_reg_11_ ( .D(n16), .CP(clk0), .Q(sfp_sum_in_0_r[11]) );
  DFQD1 sfp_sum_in_0_r_reg_10_ ( .D(n15), .CP(clk0), .Q(sfp_sum_in_0_r[10]) );
  DFQD1 sfp_sum_in_0_r_reg_9_ ( .D(n14), .CP(clk0), .Q(sfp_sum_in_0_r[9]) );
  DFQD1 sfp_sum_in_0_r_reg_8_ ( .D(n13), .CP(clk0), .Q(sfp_sum_in_0_r[8]) );
  DFQD1 sfp_sum_in_0_r_reg_7_ ( .D(n12), .CP(clk0), .Q(sfp_sum_in_0_r[7]) );
  DFQD1 sfp_sum_in_0_r_reg_6_ ( .D(n11), .CP(clk0), .Q(sfp_sum_in_0_r[6]) );
  DFQD1 sfp_sum_in_0_r_reg_5_ ( .D(n10), .CP(clk0), .Q(sfp_sum_in_0_r[5]) );
  DFQD1 sfp_sum_in_0_r_reg_4_ ( .D(n9), .CP(clk0), .Q(sfp_sum_in_0_r[4]) );
  DFQD1 sfp_sum_in_0_r_reg_3_ ( .D(n8), .CP(clk0), .Q(sfp_sum_in_0_r[3]) );
  DFQD1 sfp_sum_in_0_r_reg_2_ ( .D(n7), .CP(clk0), .Q(sfp_sum_in_0_r[2]) );
  DFQD1 sfp_sum_in_0_r_reg_1_ ( .D(n6), .CP(clk0), .Q(sfp_sum_in_0_r[1]) );
  DFQD1 sfp_sum_in_0_r_reg_0_ ( .D(n5), .CP(clk0), .Q(sfp_sum_in_0_r[0]) );
  DFQD1 sfp_sum_in_1_r_reg_23_ ( .D(n52), .CP(clk1), .Q(sfp_sum_in_1_r[23]) );
  DFQD1 sfp_sum_in_1_r_reg_22_ ( .D(n51), .CP(clk1), .Q(sfp_sum_in_1_r[22]) );
  DFQD1 sfp_sum_in_1_r_reg_21_ ( .D(n50), .CP(clk1), .Q(sfp_sum_in_1_r[21]) );
  DFQD1 sfp_sum_in_1_r_reg_20_ ( .D(n49), .CP(clk1), .Q(sfp_sum_in_1_r[20]) );
  DFQD1 sfp_sum_in_1_r_reg_19_ ( .D(n48), .CP(clk1), .Q(sfp_sum_in_1_r[19]) );
  DFQD1 sfp_sum_in_1_r_reg_18_ ( .D(n47), .CP(clk1), .Q(sfp_sum_in_1_r[18]) );
  DFQD1 sfp_sum_in_1_r_reg_17_ ( .D(n46), .CP(clk1), .Q(sfp_sum_in_1_r[17]) );
  DFQD1 sfp_sum_in_1_r_reg_16_ ( .D(n45), .CP(clk1), .Q(sfp_sum_in_1_r[16]) );
  DFQD1 sfp_sum_in_1_r_reg_15_ ( .D(n44), .CP(clk1), .Q(sfp_sum_in_1_r[15]) );
  DFQD1 sfp_sum_in_1_r_reg_14_ ( .D(n43), .CP(clk1), .Q(sfp_sum_in_1_r[14]) );
  DFQD1 sfp_sum_in_1_r_reg_13_ ( .D(n42), .CP(clk1), .Q(sfp_sum_in_1_r[13]) );
  DFQD1 sfp_sum_in_1_r_reg_12_ ( .D(n41), .CP(clk1), .Q(sfp_sum_in_1_r[12]) );
  DFQD1 sfp_sum_in_1_r_reg_11_ ( .D(n40), .CP(clk1), .Q(sfp_sum_in_1_r[11]) );
  DFQD1 sfp_sum_in_1_r_reg_10_ ( .D(n39), .CP(clk1), .Q(sfp_sum_in_1_r[10]) );
  DFQD1 sfp_sum_in_1_r_reg_9_ ( .D(n38), .CP(clk1), .Q(sfp_sum_in_1_r[9]) );
  DFQD1 sfp_sum_in_1_r_reg_8_ ( .D(n37), .CP(clk1), .Q(sfp_sum_in_1_r[8]) );
  DFQD1 sfp_sum_in_1_r_reg_7_ ( .D(n36), .CP(clk1), .Q(sfp_sum_in_1_r[7]) );
  DFQD1 sfp_sum_in_1_r_reg_6_ ( .D(n35), .CP(clk1), .Q(sfp_sum_in_1_r[6]) );
  DFQD1 sfp_sum_in_1_r_reg_5_ ( .D(n34), .CP(clk1), .Q(sfp_sum_in_1_r[5]) );
  DFQD1 sfp_sum_in_1_r_reg_4_ ( .D(n33), .CP(clk1), .Q(sfp_sum_in_1_r[4]) );
  DFQD1 sfp_sum_in_1_r_reg_3_ ( .D(n32), .CP(clk1), .Q(sfp_sum_in_1_r[3]) );
  DFQD1 sfp_sum_in_1_r_reg_2_ ( .D(n31), .CP(clk1), .Q(sfp_sum_in_1_r[2]) );
  DFQD1 sfp_sum_in_1_r_reg_1_ ( .D(n30), .CP(clk1), .Q(sfp_sum_in_1_r[1]) );
  DFQD1 sfp_sum_in_1_r_reg_0_ ( .D(n29), .CP(clk1), .Q(sfp_sum_in_1_r[0]) );
  INR2XD0 U55 ( .A1(fifo0_empty), .B1(reset1), .ZN(n76) );
  INVD1 U56 ( .I(n76), .ZN(n53) );
  NR2D2 U57 ( .A1(reset0), .A2(fifo1_empty), .ZN(n1) );
  NR2D2 U58 ( .A1(reset1), .A2(fifo0_empty), .ZN(n3) );
  MOAI22D0 U59 ( .A1(n53), .A2(n75), .B1(n3), .B2(sum_out_0_1[0]), .ZN(n29) );
  MOAI22D0 U60 ( .A1(n53), .A2(n74), .B1(n3), .B2(sum_out_0_1[1]), .ZN(n30) );
  MOAI22D0 U61 ( .A1(n53), .A2(n73), .B1(n3), .B2(sum_out_0_1[2]), .ZN(n31) );
  MOAI22D0 U62 ( .A1(n53), .A2(n72), .B1(n3), .B2(sum_out_0_1[3]), .ZN(n32) );
  MOAI22D0 U63 ( .A1(n53), .A2(n71), .B1(n3), .B2(sum_out_0_1[4]), .ZN(n33) );
  MOAI22D0 U64 ( .A1(n53), .A2(n69), .B1(n3), .B2(sum_out_0_1[6]), .ZN(n35) );
  MOAI22D0 U65 ( .A1(n53), .A2(n68), .B1(n3), .B2(sum_out_0_1[7]), .ZN(n36) );
  MOAI22D0 U66 ( .A1(n53), .A2(n67), .B1(n3), .B2(sum_out_0_1[8]), .ZN(n37) );
  MOAI22D0 U67 ( .A1(n53), .A2(n66), .B1(n3), .B2(sum_out_0_1[9]), .ZN(n38) );
  MOAI22D0 U68 ( .A1(n53), .A2(n65), .B1(n3), .B2(sum_out_0_1[10]), .ZN(n39)
         );
  MOAI22D0 U69 ( .A1(n53), .A2(n64), .B1(n3), .B2(sum_out_0_1[11]), .ZN(n40)
         );
  MOAI22D0 U70 ( .A1(n53), .A2(n63), .B1(n3), .B2(sum_out_0_1[12]), .ZN(n41)
         );
  MOAI22D0 U71 ( .A1(n53), .A2(n62), .B1(n3), .B2(sum_out_0_1[13]), .ZN(n42)
         );
  MOAI22D0 U72 ( .A1(n53), .A2(n61), .B1(n3), .B2(sum_out_0_1[14]), .ZN(n43)
         );
  MOAI22D0 U73 ( .A1(n53), .A2(n60), .B1(n3), .B2(sum_out_0_1[15]), .ZN(n44)
         );
  MOAI22D0 U74 ( .A1(n53), .A2(n59), .B1(n3), .B2(sum_out_0_1[16]), .ZN(n45)
         );
  MOAI22D0 U75 ( .A1(n53), .A2(n58), .B1(n3), .B2(sum_out_0_1[17]), .ZN(n46)
         );
  MOAI22D0 U76 ( .A1(n53), .A2(n57), .B1(n3), .B2(sum_out_0_1[18]), .ZN(n47)
         );
  MOAI22D0 U77 ( .A1(n53), .A2(n56), .B1(n3), .B2(sum_out_0_1[19]), .ZN(n48)
         );
  MOAI22D0 U78 ( .A1(n53), .A2(n54), .B1(n3), .B2(sum_out_0_1[21]), .ZN(n50)
         );
  INVD0 U79 ( .I(sfp_sum_in_1_r[2]), .ZN(n73) );
  INVD0 U80 ( .I(sfp_sum_in_1_r[7]), .ZN(n68) );
  INVD0 U81 ( .I(sfp_sum_in_1_r[12]), .ZN(n63) );
  INVD0 U82 ( .I(sfp_sum_in_1_r[17]), .ZN(n58) );
  MOAI22D0 U83 ( .A1(n53), .A2(n70), .B1(n3), .B2(sum_out_0_1[5]), .ZN(n34) );
  MOAI22D0 U84 ( .A1(n53), .A2(n55), .B1(n3), .B2(sum_out_0_1[20]), .ZN(n49)
         );
  INR2D2 U85 ( .A1(fifo1_empty), .B1(reset0), .ZN(n77) );
  INVD0 U86 ( .I(sfp_sum_in_1_r[21]), .ZN(n54) );
  INVD0 U87 ( .I(sfp_sum_in_1_r[20]), .ZN(n55) );
  INVD0 U88 ( .I(sfp_sum_in_1_r[19]), .ZN(n56) );
  INVD0 U89 ( .I(sfp_sum_in_1_r[18]), .ZN(n57) );
  INVD0 U90 ( .I(sfp_sum_in_1_r[16]), .ZN(n59) );
  INVD0 U91 ( .I(sfp_sum_in_1_r[15]), .ZN(n60) );
  INVD0 U92 ( .I(sfp_sum_in_1_r[14]), .ZN(n61) );
  INVD0 U93 ( .I(sfp_sum_in_1_r[13]), .ZN(n62) );
  INVD0 U94 ( .I(sfp_sum_in_1_r[11]), .ZN(n64) );
  INVD0 U95 ( .I(sfp_sum_in_1_r[10]), .ZN(n65) );
  INVD0 U96 ( .I(sfp_sum_in_1_r[9]), .ZN(n66) );
  INVD0 U97 ( .I(sfp_sum_in_1_r[8]), .ZN(n67) );
  INVD0 U98 ( .I(sfp_sum_in_1_r[6]), .ZN(n69) );
  INVD0 U99 ( .I(sfp_sum_in_1_r[5]), .ZN(n70) );
  INVD0 U100 ( .I(sfp_sum_in_1_r[4]), .ZN(n71) );
  INVD0 U101 ( .I(sfp_sum_in_1_r[3]), .ZN(n72) );
  INVD0 U102 ( .I(sfp_sum_in_1_r[1]), .ZN(n74) );
  INVD0 U103 ( .I(sfp_sum_in_1_r[0]), .ZN(n75) );
endmodule

