using JLD2, YAML

struct InitialState
    parameters::Dict{String, Any}
    initial_conditions::Dict{String, Any}
end

paras = YAML.load_file("bcfin/core-test/config.yaml")

dir = joinpath(splitpath(dirname(pathof(@__MODULE__)))[1:(end - 1)])

parameters = load(joinpath(dir, "data/austria/parameters/2010Q1.jld2"))

parameters["vec_tau_PIT"] = paras["base_vec_tau_PIT"]
parameters["vec_thr_lo_PIT"] = paras["base_vec_tau_PIT"]
parameters["vec_thr_up_PIT"] = paras["base_vec_tau_PIT"]
parameters["vec_addition_PIT"] = paras["base_vec_tau_PIT"]

initial_conditions = load(joinpath(dir, "data/austria/initial_conditions/2010Q1.jld2"))

const AUSTRIA2010Q1 = InitialState(parameters, initial_conditions)

parameters = load(joinpath(dir, "data/italy/parameters/2010Q1.jld2"))
initial_conditions = load(joinpath(dir, "data/italy/initial_conditions/2010Q1.jld2"))

const ITALY2010Q1 = InitialState(parameters, initial_conditions)

parameters = load(joinpath(dir, "data/steady_state/parameters/2010Q1.jld2"))
initial_conditions = load(joinpath(dir, "data/steady_state/initial_conditions/2010Q1.jld2"))

const STEADY_STATE2010Q1 = InitialState(parameters, initial_conditions)
