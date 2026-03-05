# Floorplan
floorPlan -s 1000 1000 50 50 50 50

timeDesign -preplace -prefix preplace

globalNetConnect VDD -type pgpin -pin VDD -inst * -verbose
globalNetConnect VSS -type pgpin -pin VSS -inst * -verbose

addRing -spacing {top 1 bottom 1 left 1 right 1} -width {top 2 bottom 2 left 2 right 2}  -layer {top M1 bottom M1 left M2 right M2} -center 1 -type core_rings -nets {VSS  VDD}
setAddStripeMode -break_at {block_ring}

### Note: Change the number of strip  by looking at the layout #########
addStripe -nets {VDD VSS} -layer M4 -direction horizontal -width 2 -spacing 6 -number_of_sets 40 -start_from left -start 20 -stop 1180

#addStripe -skip_via_on_wire_shape Noshape -block_ring_top_layer_limit M1 -max_same_layer_jog_length 0.8 -padcore_ring_bottom_layer_limit M1 -number_of_sets 5 -skip_via_on_pin Standardcell -stacked_via_top_layer M8 -padcore_ring_top_layer_limit M1 -spacing 0.4 -merge_stripes_value 0.1 -direction horizontal -layer M5 -block_ring_bottom_layer_limit M1 -width 1 -area {} -nets {VDD VSS} -stacked_via_bottom_layer M1
#addStripe -nets {VDD VSS} -layer M4 -direction vertical -width 1.8 -spacing 1.8 -number_of_sets 5 -start_from left -start 80 -stop 180 

#setObjFPlanBox Instance kmem_instance 51.218 881.5915 201.218 1161.5915
#setObjFPlanBox Instance qmem_instance 51.22 546.1355 201.22 826.1355
#setObjFPlanBox Instance psum_mem_instance 113.4255 48.741 783.4255 198.741

setObjFPlanBox Instance qmem_instance 50 50 325 325
setObjFPlanBox Instance kmem_instance 50 350 325 625
setObjFPlanBox Instance psum_mem_instance 50 650 325 925

#addHaloToBlock 3 3 3 3 -cell psum_mem_instance
#addHaloToBlock 3 3 3 3 -cell kmem_instance
#addHaloToBlock 3 3 3 3 -cell qmem_instance
#addHaloToBlock {3 3 3 3} psum_mem_instance
#addHaloToBlock {3 3 3 3} kmem_instance
#addHaloToBlock {3 3 3 3} qmem_instance

addRing -nets {VDD VSS} -type block_rings -around each_block -layer {top M1 bottom M1 left M2 right M2} -width {top 0.5 bottom 0.5 left 0.5 right 0.5} -spacing {top 0.5 bottom 0.5 left 0.5 right 0.5} 

globalNetConnect VDD -type pgpin -pin VDD -sinst qmem_instance -verbose -override
globalNetConnect VSS -type pgpin -pin VSS -sinst qmem_instance -verbose -override
globalNetConnect VDD -type pgpin -pin VDD -sinst kmem_instance -verbose -override
globalNetConnect VSS -type pgpin -pin VSS -sinst kmem_instance -verbose -override
globalNetConnect VDD -type pgpin -pin VDD -sinst psum_mem_instance -verbose -override
globalNetConnect VSS -type pgpin -pin VSS -sinst psum_mem_instance -verbose -override
sroute

verifyConnectivity


