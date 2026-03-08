# Floorplan
floorPlan -site core -r 1 0.70 20 20 20 20

timeDesign -preplace -prefix preplace

globalNetConnect VDD -type pgpin -pin VDD -inst * -verbose
globalNetConnect VSS -type pgpin -pin VSS -inst * -verbose

addRing -type core_rings -nets {VDD VSS} -layer {top M3 bottom M3 left M4 right M4} -width 4 -spacing 2 -center 1

setAddStripeMode -break_at {block_ring}

### Note: Change the number of strip  by looking at the layout #########
addStripe -nets {VDD VSS} -layer M4 -direction vertical -width 3 -spacing 10 -number_of_sets 6
#################################################

#addStripe -nets {VDD VSS} -layer M4 -direction vertical -width 1.8 -spacing 1.8 -number_of_sets 5 -start_from left -start 80 -stop 180
 
setObjFPlanBox Instance add_instance0 25 25.831 52.971 52.231
setObjFPlanBox Instance add_instance1 25 75.4675 52.9745 99.8675
setObjFPlanBox Instance add_instance0 25 25.831 52.971 52.231 
 


sroute

verifyConnectivity


