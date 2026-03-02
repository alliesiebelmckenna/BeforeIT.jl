"""
    corporate_income_tax_payable (Pi_i, vec_tau_FIRM, thr_FIRM)
"""

## Personal income tax (PIT) functions
function corporate_income_tax_payable(Pi_i, vec_tau_FIRM, thr_FIRM)
    
    # Assuming vec_tau_FIRM is a vector containing 2 elements: a lower small business rate and a higher general corporate rate
    sm_biz_rate = minimum(vec_tau_FIRM)
    gen_corp_rate = maximum(vec_tau_FIRM) 

    corp_tax_pybl = sm_biz_rate * minimum([maximum([0.0, Pi_i]), thr_FIRM]) + gen_corp_rate * maximum([(Pi_i - thr_FIRM), 0.0]) 

    return corp_tax_pybl
end