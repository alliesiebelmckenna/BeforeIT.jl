# update wages for workers
function update_workers_wages!(model::AbstractModel)
    w_act, firms = model.w_act, model.firms
    w_i = firms.w_i
    for (i, h) in enumerate(w_act.O_h)
        if h != zero(typeInt)
            w_act.w_h[i] = w_i[h]
        end
    end
    return
end

function households_income_act(model; expected = false)
    w_act, prop = model.w_act, model.prop

    w_h, O_h, tau_SIW, tau_INC = w_act.w_h, w_act.O_h, model.prop.tau_SIW, model.prop.tau_INC
    theta_UB, sb_other, P_bar_HH = model.prop.theta_UB, model.gov.sb_other, model.agg.P_bar_HH

    # provincial personal income tax parameters
    vec_tau_PIT, vec_thr_lo_PIT = prop.vec_tau_PIT, prop.vec_thr_lo_PIT

    # federal personal income tax parameters
    vec_tau_fed_PIT, vec_thr_lo_fed_PIT = prop.vec_tau_fed_PIT, prop.vec_thr_lo_fed_PIT

    pi_e = expected ? model.agg.pi_e : zero(typeFloat)

    Y_h = zeros(typeFloat, length(w_h))
    for h in eachindex(w_h)
        if O_h[h] != 0
            # provincial personal income tax functionality
            inc_tax_pybl_h = income_tax_payable(w_h[h], vec_tau_PIT, vec_thr_lo_PIT, tau_SIW)
            # federal personal income tax functionality
            fed_inc_tax_pybl_h = income_tax_payable(w_h[h], vec_tau_fed_PIT, vec_thr_lo_fed_PIT, tau_SIW)
            # new Y_h with both provincial and federal personal income tax functionality
            Y_h[h] = (w_h[h] * (1 - tau_SIW) - inc_tax_pybl_h - fed_inc_tax_pybl_h + sb_other) * P_bar_HH * (1 + pi_e)
            # old Y_h:
            # Y_h[h] = (w_h[h] * (1 - tau_SIW - tau_INC * (1 - tau_SIW)) + sb_other) * P_bar_HH * (1 + pi_e)
        else
            Y_h[h] = (theta_UB * w_h[h] + sb_other) * P_bar_HH * (1 + pi_e)
        end
    end
    return Y_h
end
function set_households_income_act!(model; expected = false)
    return model.w_act.Y_h .= households_income_act(model; expected)
end

function households_income_inact(model::AbstractModel; expected = false)
    w_inact = model.w_inact

    H_inact, sb_inact = length(w_inact), model.gov.sb_inact
    sb_other, P_bar_HH = model.gov.sb_other, model.agg.P_bar_HH

    pi_e = expected ? model.agg.pi_e : zero(typeFloat)

    Y_h = zeros(typeFloat, H_inact)
    for h in 1:H_inact
        Y_h[h] = (sb_inact + sb_other) * P_bar_HH * (1 + pi_e)
    end
    return Y_h
end
function set_households_income_inact!(model; expected = false)
    return model.w_inact.Y_h .= households_income_inact(model; expected)
end

function households_income_firms(model::AbstractModel; expected = false)
    firms, prop = model.firms, model.prop
    tau_INC, tau_FIRM, theta_DIV = model.prop.tau_INC, model.prop.tau_FIRM, model.prop.theta_DIV
    sb_other, P_bar_HH = model.gov.sb_other, model.agg.P_bar_HH
    # provincial personal income tax parameters
    vec_tau_PIT, vec_thr_lo_PIT = prop.vec_tau_PIT, prop.vec_thr_lo_PIT
    # federal personal income tax parameters
    vec_tau_fed_PIT, vec_thr_lo_fed_PIT = prop.vec_tau_fed_PIT, prop.vec_thr_lo_fed_PIT
    # corporate income tax parameters
    vec_tau_FIRM, thr_FIRM = prop.vec_tau_FIRM, prop.thr_FIRM

    Pi_i = expected ? firms.Pi_e_i : firms.Pi_i
    pi_e = expected ? model.agg.pi_e : zero(typeFloat)

    Y_h = zeros(typeFloat, length(Pi_i))
    
    inc_tax_pybl_firms = zeros(typeFloat, length(Pi_i))

    # Calculate provincial income tax for each firm owner i
    for i in eachindex(Pi_i)
        inc_tax_pybl_firms[i] = income_tax_payable_firms(Pi_i[i], theta_DIV, vec_tau_FIRM, thr_FIRM, vec_tau_PIT, vec_thr_lo_PIT)
    end

    fed_inc_tax_pybl_firms = zeros(typeFloat, length(Pi_i))

    # Calculate federal income tax for each firm owner i
    for i in eachindex(Pi_i)
        fed_inc_tax_pybl_firms[i] = income_tax_payable_firms(Pi_i[i], theta_DIV, vec_tau_FIRM, thr_FIRM, vec_tau_fed_PIT, vec_thr_lo_fed_PIT)
    end

    for i in eachindex(Pi_i)
        corp_tax_pybl_i = corporate_income_tax_payable(Pi_i[i], vec_tau_FIRM, thr_FIRM)
        Y_h[i] = theta_DIV * (max(0, Pi_i[i]) - corp_tax_pybl_i) - inc_tax_pybl_firms[i] - fed_inc_tax_pybl_firms[i] + sb_other * P_bar_HH * (1 + pi_e)
    end

    # Previous iteration of new Y_h:
    # # Calculate net disposable income for each firm owner i
    # for i in eachindex(Pi_i)
    #     Y_h[i] = theta_DIV * (1 - tau_FIRM) * max(0, Pi_i[i]) - inc_tax_pybl_firms[i] - fed_inc_tax_pybl_firms[i] + sb_other * P_bar_HH * (1 + pi_e)
    # end
    
    # # Old Y_h:
    # for i in eachindex(Pi_i)
    #     Y_h[i] = theta_DIV * (1 - tau_INC) * (1 - tau_FIRM) * max(0, Pi_i[i]) + sb_other * P_bar_HH * (1 + pi_e)
    # end
    return Y_h
end
function set_households_income_firms!(model; expected = false)
    return model.firms.Y_h .= households_income_firms(model; expected)
end

function households_income_bank(model; expected = false)
    bank, prop = model.bank, model.prop

    tau_INC, tau_FIRM, theta_DIV = model.prop.tau_INC, model.prop.tau_FIRM, model.prop.theta_DIV
    sb_other, P_bar_HH = model.gov.sb_other, model.agg.P_bar_HH

    # provincial income tax parameters
    vec_tau_PIT, vec_thr_lo_PIT = prop.vec_tau_PIT, prop.vec_thr_lo_PIT

    # federal income tax parameters
    vec_tau_fed_PIT, vec_thr_lo_fed_PIT = prop.vec_tau_fed_PIT, prop.vec_thr_lo_fed_PIT

    Pi_k = expected ? bank.Pi_e_k : bank.Pi_k
    pi_e = expected ? model.agg.pi_e : zero(typeFloat)

    Y_h = zeros(typeFloat, length(Pi_k))

    inc_tax_pybl_bank = zeros(typeFloat, length(Pi_k))

    # Calculate provincial personal income tax for bank owner k
    for k in eachindex(Pi_k)
        inc_tax_pybl_bank[k] = income_tax_payable_firms(Pi_k[k], theta_DIV, vec_tau_FIRM, thr_FIRM, vec_tau_PIT, vec_thr_lo_PIT)
    end

    fed_inc_tax_pybl_bank = zeros(typeFloat, length(Pi_k))

    # Calculate provincial personal income tax for bank owner k
    for k in eachindex(Pi_k)
        fed_inc_tax_pybl_bank[k] = income_tax_payable_firms(Pi_k[k], theta_DIV, vec_tau_FIRM, thr_FIRM, vec_tau_fed_PIT, vec_thr_lo_fed_PIT)
    end

    # Calculate net disposable income for bank owner k
    for k in eachindex(Pi_k)
        corp_tax_pybl_k = corporate_income_tax_payable(Pi_k[k], vec_tau_FIRM, thr_FIRM)
        Y_h[k] = theta_DIV * (max(0, Pi_k[k]) - corp_tax_pybl_k) - inc_tax_pybl_bank[k] - fed_inc_tax_pybl_bank[k] + sb_other * P_bar_HH * (1 + pi_e)
    end
    
    # Previous iteration of Y_h
    # # Calculate net disposable income for bank owner k
    # for k in eachindex(Pi_k)
    #     Y_h[k] = theta_DIV * (1 - tau_FIRM) * max(0, Pi_k[k]) - inc_tax_pybl_bank[k] - fed_inc_tax_pybl_bank[k] + sb_other * P_bar_HH * (1 + pi_e)
    # end

    # household income/budget/deposit functions below for bank owner assume a single bank
    # TODO: modify those functions to allow for more than one bank (low priority)
    Y_h = only(Y_h)
    # # Old Y_h:
    # Y_h = theta_DIV * (1 - tau_INC) * (1 - tau_FIRM) * max(0, Pi_k) + sb_other * P_bar_HH * (1 + pi_e)
    return Y_h
end
function set_households_income_bank!(model; expected = false)
    return model.bank.Y_h = households_income_bank(model; expected)
end

function households_budget_act(model::AbstractModel)
    w_act = model.w_act

    psi, psi_H, tau_VAT, tau_CF = model.prop.psi, model.prop.psi_H, model.prop.tau_VAT, model.prop.tau_CF

    Y_e_h = households_income_act(model; expected = true)

    C_d_h = psi * Y_e_h / (1 + tau_VAT)
    I_d_h = psi_H * Y_e_h / (1 + tau_CF)

    return C_d_h, I_d_h
end
function set_households_budget_act!(model::AbstractModel)
    w_act = model.w_act
    C_d_h, I_d_h = households_budget_act(model)
    w_act.C_d_h .= C_d_h
    return w_act.I_d_h .= I_d_h
end

function households_budget_inact(model::AbstractModel)
    w_inact = model.w_inact

    psi, psi_H, tau_VAT, tau_CF = model.prop.psi, model.prop.psi_H, model.prop.tau_VAT, model.prop.tau_CF

    Y_e_h = households_income_inact(model; expected = true)

    C_d_h = psi * Y_e_h / (1 + tau_VAT)
    I_d_h = psi_H * Y_e_h / (1 + tau_CF)

    return C_d_h, I_d_h
end
function set_households_budget_inact!(model::AbstractModel)
    w_inact = model.w_inact
    C_d_h, I_d_h = households_budget_inact(model)
    w_inact.C_d_h .= C_d_h
    return w_inact.I_d_h .= I_d_h
end

function households_budget_firms(model::AbstractModel)
    firms = model.firms

    psi, psi_H, tau_VAT, tau_CF = model.prop.psi, model.prop.psi_H, model.prop.tau_VAT, model.prop.tau_CF

    Y_e_h = households_income_firms(model; expected = true)

    C_d_h = psi * Y_e_h / (1 + tau_VAT)
    I_d_h = psi_H * Y_e_h / (1 + tau_CF)

    return C_d_h, I_d_h
end
function set_households_budget_firms!(model::AbstractModel)
    firms = model.firms
    C_d_h, I_d_h = households_budget_firms(model)
    firms.C_d_h .= C_d_h
    return firms.I_d_h .= I_d_h
end

function households_budget_bank(model)
    bank = model.bank

    psi, psi_H, tau_VAT, tau_CF = model.prop.psi, model.prop.psi_H, model.prop.tau_VAT, model.prop.tau_CF

    Y_e_h = households_income_bank(model; expected = true)
    C_d_h = psi * Y_e_h / (1 + tau_VAT)
    I_d_h = psi_H * Y_e_h / (1 + tau_CF)

    return C_d_h, I_d_h
end
function set_households_budget_bank!(model)
    bank = model.bank
    C_d_h, I_d_h = households_budget_bank(model)
    bank.C_d_h = C_d_h
    return bank.I_d_h = I_d_h
end

function set_households_deposits_act!(model)
    D_h = households_deposits(model.w_act, model)
    return model.w_act.D_h .= D_h
end
function set_households_deposits_inact!(model)
    D_h = households_deposits(model.w_inact, model)
    return model.w_inact.D_h .= D_h
end
function set_households_deposits_firms!(model)
    D_h = households_deposits(model.firms, model)
    return model.firms.D_h .= D_h
end
function set_households_deposits_bank!(model)
    D_h = households_deposits(model.bank, model)
    return model.bank.D_h = D_h
end

function households_deposits(households, model)
    tau_VAT, tau_CF = model.prop.tau_VAT, model.prop.tau_CF
    r_bar = model.cb.r_bar
    r = model.bank.r

    DD_h =
        households.Y_h - (1 + tau_VAT) * households.C_h - (1 + tau_CF) * households.I_h +
        r_bar * max.(0, households.D_h) - r * max.(0, -households.D_h)
    D_h = households.D_h + DD_h
    return D_h
end
