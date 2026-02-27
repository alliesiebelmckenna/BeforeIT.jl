import BeforeIT as Bit
import StatsBase: mean, std
using Plots, StatsPlots, YAML

# Load model parameters
paras = YAML.load_file("bcfin/config.yaml")

p, ic = Bit.AUSTRIA2010Q1.parameters, Bit.AUSTRIA2010Q1.initial_conditions

include("src/utils/pit_functions.jl")

# PIT rates
vec_tau_PIT = paras["base_vec_tau_INC"]

# Lower PIT thresholds
vec_thr_lo_PIT = paras["base_vec_thr_lo_INC"]

# Add PIT rates and thresholds to parameters dictionary
p["vec_tau_PIT"] = vec_tau_PIT
p["vec_thr_lo_PIT"] = vec_thr_lo_PIT
p["vec_thr_up_PIT"] = upper_thresholds(vec_thr_lo_PIT)
p["vec_addition_PIT"] = addition(vec_tau_PIT, vec_thr_lo_PIT)

model = Bit.Model(p, ic);

tax_model = TaxModel((w_act, w_inact, firms, bank, cb, government, rotw, agg, properties, data));

# We can run now the model for a number of epochs
T = paras["T"]

for _ in 1:T
    Bit.step!(tax_model; parallel = true)
    Bit.collect_data!(tax_model)
end
