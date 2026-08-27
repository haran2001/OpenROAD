# Reproduce PR #11124's hierarchical extraction path using the existing
# cross-chiplet OpenROAD fixture plus a minimal assembly HBV rule.
read_3dbx 3dic_cross.3dbx

set die_rules [file normalize ../../../test/Nangate45/Nangate45.rcx_rules]
set assembly_rules [file normalize 3dic_rcx_assembly.rules]
set tech_names [get_db techs .name]
puts "PR11124_TECHS=$tech_names"
foreach tech_name $tech_names {
  set_extraction_rules_file -tech $tech_name $die_rules
}
set_extraction_rules_file -assembly $assembly_rules

extract_parasitics

set out_dir [file normalize ../../../artifacts/pr11124]
file mkdir $out_dir
write_spef $out_dir/repro.spef
puts "PR11124_OUTPUT_DIR=$out_dir"
