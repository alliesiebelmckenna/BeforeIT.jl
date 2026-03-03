"""
    gov_expenditure(model)

Computes government expenditure on consumption and transfers to households.

# Returns
- `C_G`: government consumption
- `C_d_j`: local government consumptions
"""
function gov_expenditure(model)
    gov = model.gov

    c_G_g, P_bar_g, pi_e = model.prop.c_G_g, model.agg.P_bar_g, model.agg.pi_e

    epsilon_G = randn() * gov.sigma_G
    C_G = exp(gov.alpha_G * log(gov.C_G) + gov.beta_G + epsilon_G)
    J = length(gov.C_d_j)
    C_d_j = C_G ./ J .* ones(J) .* sum(c_G_g .* P_bar_g) .* (1 + pi_e)

    return C_G, C_d_j
end
function set_gov_expenditure!(model)
    C_G, C_d_j = gov_expenditure(model)
    model.gov.C_G = C_G
    return model.gov.C_d_j .= C_d_j
end

""" 
    gov_revenues(model)

Computes government revenues from taxes and social security contributions.
The government collects taxes on labour income, capital income, value added,
and corporate income. It also collects social security contributions from
workers and firms. The government also collects taxes on consumption and
capital formation. Finally, the government collects taxes on exports and
imports.

# Returns
- `Y_G`: government revenues
"""
function gov_revenues(model::AbstractModel)
    gov, w_act, w_inact = model.gov, model.w_act, model.w_inact
    firms, bank, rotw = model.firms, model.bank, model.rotw

    prop, P_bar_HH = model.prop, model.agg.P_bar_HH
    tau_SIF, tau_SIW, tau_INC, tau_CF, tau_VAT = prop.tau_SIF, prop.tau_SIW, prop.tau_INC, prop.tau_CF, prop.tau_VAT
    # new personal income tax parameters
    vec_tau_PIT, vec_thr_lo_PIT, vec_thr_up_PIT, vec_addition_PIT = prop.vec_tau_PIT, prop.vec_thr_lo_PIT, prop.vec_thr_up_PIT, prop.vec_addition_PIT    
    tau_FIRM, tau_EXPORT, theta_DIV = prop.tau_FIRM, prop.tau_EXPORT, prop.theta_DIV

    # corporate income tax parameters
    vec_tau_FIRM, thr_FIRM = model.prop.vec_tau_FIRM, model.prop.thr_FIRM
    Pi_i, Pi_k = firms.Pi_i, bank.Pi_k
    # compute total wages, consumption and investment
    tot_wages_emp = sum(w_act.w_h[w_act.O_h .!= 0])
    tot_C_h = sum(w_act.C_h) + sum(w_inact.C_h) + sum(firms.C_h) + bank.C_h
    tot_I_h = sum(w_act.I_h) + sum(w_inact.I_h) + sum(firms.I_h) + bank.I_h

    # compute government revenues
    social_security = (tau_SIF + tau_SIW) * tot_wages_emp * P_bar_HH
    
    # New personal income tax specification:
    vec_inc_tax_pybl = zeros(length(w_act))

    for i in 1:length(w_act)
        if w_act.O_h[i] == 0
            continue
        else
            inc_i = w_act.w_h[i]
            vec_inc_tax_pybl[i] = income_tax_payable(
                inc_i, vec_tau_PIT, vec_thr_lo_PIT, tau_SIW
            )
        end
    end

    # New labour_income (personal income tax on workers)
    labour_income = sum(vec_inc_tax_pybl)
    # Old personal income tax specification:
    old_labour_income = tau_INC * (1 - tau_SIW) * P_bar_HH * tot_wages_emp
    value_added = tau_VAT * tot_C_h
    
    # New capital_income (personal income tax on firm and bank owners)
    inc_tax_pybl_firms = zeros(typeFloat, length(Pi_i))

    # Calculate provincial income tax for each firm owner i
    for i in eachindex(Pi_i)
        inc_tax_pybl_firms[i] = income_tax_payable_firms(Pi_i[i], theta_DIV, vec_tau_FIRM, thr_FIRM, vec_tau_PIT, vec_thr_lo_PIT)
    end

    inc_tax_pybl_bank = zeros(typeFloat, length(Pi_k))

    # Calculate provincial income tax for each bank owner k
    for k in eachindex(Pi_k)
        inc_tax_pybl_bank[k] = income_tax_payable_firms(Pi_k[k], theta_DIV, vec_tau_FIRM, thr_FIRM, vec_tau_PIT, vec_thr_lo_PIT)
    end

    capital_income = sum(inc_tax_pybl_firms) + sum(inc_tax_pybl_bank)

    # # Old capital_income
    # capital_income = tau_INC * (1 - tau_FIRM) * theta_DIV * (sum(pos.(firms.Pi_i)) + pos(bank.Pi_k))

    # New corporate_income (corporate income tax)
    corp_tax_pybl = zeros(length(firms))

    for i in 1:length(firms)
        corp_tax_pybl[i] = corporate_income_tax_payable(firms.Pi_i[i], vec_tau_FIRM, thr_FIRM)
    end

    bank_corp_tax_pybl = corporate_income_tax_payable(bank.Pi_k, vec_tau_FIRM, thr_FIRM)

    corporate_income = sum(corp_tax_pybl) + bank_corp_tax_pybl
    # # Old corporate_income
    # corporate_income = tau_FIRM * (sum(pos.(firms.Pi_i)) + pos(bank.Pi_k))
    capital_formation = tau_CF * tot_I_h
    products = sum(firms.tau_Y_i .* firms.P_i .* firms.Y_i)
    production = sum(firms.tau_K_i .* firms.P_i .* firms.Y_i)
    export_ = tau_EXPORT * rotw.C_l

    Y_G =
        social_security +
        labour_income +
        value_added +
        capital_income +
        corporate_income +
        capital_formation +
        products +
        production +
        export_

    return Y_G
end
function set_gov_revenues!(model::AbstractModel)
    return model.gov.Y_G = gov_revenues(model)
end

"""
    gov_loans(model)

Computes government new government debt.

# Returns
- `L_G`: new government debt
"""
function gov_loans(model)
    gov = model.gov
    r_G, P_bar_HH, H, H_inact = model.cb.r_G, model.agg.P_bar_HH, model.prop.H, model.prop.H_inact
    theta_UB, w_h, O_h = model.prop.theta_UB, model.w_act.w_h, model.w_act.O_h

    tot_wages_unemp = sum(w_h[O_h .== 0])
    social_benefits =
        H_inact * gov.sb_inact * P_bar_HH + theta_UB * tot_wages_unemp * P_bar_HH + H * gov.sb_other * P_bar_HH

    # deficit = social benefits + consumption + payments on loans - revenues
    Pi_G = social_benefits + gov.C_j + r_G * gov.L_G - gov.Y_G
    # update government debt
    L_G = gov.L_G + Pi_G

    return L_G
end
function set_gov_loans!(model)
    return model.gov.L_G = gov_loans(model)
end

"""
    gov_social_benefits(model)

Computes social benefits paid by the government households.

# Returns
- `sb_other`: social benefits for other households
- `sb_inact`: social benefits for inactive households
"""
function gov_social_benefits(model::AbstractModel)
    gov = model.gov
    gamma_e = model.agg.gamma_e

    sb_other = gov.sb_other * (1 + gamma_e)
    sb_inact = gov.sb_inact * (1 + gamma_e)

    return sb_other, sb_inact
end
function set_gov_social_benefits!(model::AbstractModel)
    gov = model.gov
    return gov.sb_other, gov.sb_inact = gov_social_benefits(model)
end
