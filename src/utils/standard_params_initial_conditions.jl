using JLD2, YAML

struct InitialState
    parameters::Dict{String, Any}
    initial_conditions::Dict{String, Any}
end

# Load user-defined parameters
paras = YAML.load_file("configs/placeholder.yaml")

dir = joinpath(splitpath(dirname(pathof(@__MODULE__)))[1:(end - 1)])

parameters = load(joinpath(dir, "data/austria/parameters/2010Q1.jld2"))

## Provincial personal income tax parameters
# Extract variables for easy access
vec_tau_PIT = paras["base_vec_tau_PIT"]
vec_tau_thr_lo_PIT = paras["base_vec_thr_lo_PIT"]
# Add to existing parameters 
parameters["vec_tau_PIT"] = vec_tau_PIT
parameters["vec_thr_lo_PIT"] = vec_tau_thr_lo_PIT
parameters["vec_thr_up_PIT"] = upper_thresholds(vec_tau_PIT)
parameters["vec_addition_PIT"] = addition(vec_tau_PIT, vec_tau_thr_lo_PIT)

## Federal personal income tax parameters
# Extract variables for easy access
vec_tau_fed_PIT = paras["base_vec_tau_fed_PIT"]
vec_tau_thr_lo_fed_PIT = paras["base_vec_thr_lo_fed_PIT"]
# Add to existing parameters 
parameters["vec_tau_fed_PIT"] = vec_tau_fed_PIT
parameters["vec_thr_lo_fed_PIT"] = vec_tau_thr_lo_fed_PIT
parameters["vec_thr_up_fed_PIT"] = upper_thresholds(vec_tau_fed_PIT)
parameters["vec_addition_fed_PIT"] = addition(vec_tau_PIT, vec_tau_thr_lo_PIT)

## Corporate income tax
# Extract variables for easy access
vec_tau_FIRM = paras["base_vec_tau_FIRM"]
thr_FIRM = paras["base_thr_FIRM"]
# Add to existing parameters 
parameters["vec_tau_FIRM"] = vec_tau_FIRM
parameters["thr_FIRM"] = thr_FIRM

# NOTE: this only changes parameters for AUSTRIA2010Q1

## Initial conditions
initial_conditions = load(joinpath(dir, "data/austria/initial_conditions/2010Q1.jld2"))

const AUSTRIA2010Q1 = InitialState(parameters, initial_conditions)

parameters = load(joinpath(dir, "data/italy/parameters/2010Q1.jld2"))
initial_conditions = load(joinpath(dir, "data/italy/initial_conditions/2010Q1.jld2"))

const ITALY2010Q1 = InitialState(parameters, initial_conditions)

parameters = load(joinpath(dir, "data/steady_state/parameters/2010Q1.jld2"))
initial_conditions = load(joinpath(dir, "data/steady_state/initial_conditions/2010Q1.jld2"))

const STEADY_STATE2010Q1 = InitialState(parameters, initial_conditions)
