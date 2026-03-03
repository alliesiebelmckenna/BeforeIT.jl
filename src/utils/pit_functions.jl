"""
    income_tax_payable_act (inc, vec_tau, vec_thr_lo, tau_SIW)

Computes a person's income tax payable given a vector of tax rates, a vector of (lower) income thresholds, and an effective employee social contribution rate.

# Returns
- `inc_tax_pybl`: Personal income tax payable (\$)
"""

## Personal income tax (PIT) functions
function income_tax_payable(inc, vec_tau, vec_thr_lo, tau_SIW)
    
    if inc == 0
        inc_tax_pybl = 0
    else
        vec_thr_hi = upper_thresholds(vec_thr_lo)
        vec_addition = addition(vec_tau, vec_thr_lo)

        txbl_income = inc * (1 - tau_SIW)

        # Determine PIT bracket
        a = txbl_income .> vec_thr_lo
        b = txbl_income .<= vec_thr_hi
        i = findall(a .& b)

        # Pull elements from each vector
        thr_lo = only(vec_thr_lo[i])
        rate = only(vec_tau[i])
        add = only(vec_addition[i])

        inc_tax_pybl = rate * (txbl_income - thr_lo) + add
    end
    return inc_tax_pybl
end

"""
    income_tax_payable_firms(profit, theta_DIV, vec_tau_FIRM, thr_FIRM, vec_tau_PIT, vec_thr_lo_PIT)

Computes a firm owner's income tax payable given:
`profit`: annual profit
`theta_DIV`: effective dividend rate
`vec_tau_FIRM`: a lower and a higher corporate tax rate
`thr_FIRM`: threshold determining whether higher corporate tax rate comes into effective
`vec_tau_PIT`: a vector of personal income tax rates
`vec_thr_lo_PIT`: a vector of (lower) personal income thresholds

# Returns
- `inc_tax_pybl_firms`: Personal income tax payable on dividends of firm owner (\$)
"""

## Personal income tax (PIT) functions
function income_tax_payable_firms(profit, theta_DIV, vec_tau_FIRM, thr_FIRM, vec_tau_PIT, vec_thr_lo_PIT)
    if profit <= 0
        inc_tax_pybl_firms = 0
    else
        corp_tax_pybl = corporate_income_tax_payable(profit, vec_tau_FIRM, thr_FIRM)
        dividends = theta_DIV * (profit - corp_tax_pybl)
        inc_tax_pybl_firms = income_tax_payable(dividends, vec_tau_PIT, vec_thr_lo_PIT, 0)
    end
    return inc_tax_pybl_firms
end

"""
    upper_thresholds(vec_thr_lo, val=1e5)

Computes a vector of the upper limits of personal income tax brackets given a vector of lower tax bracket limits. Takes val (default set to 1e5) as an arbitrary upper limit on the highest tax bracket.

Example:
(Lowest) 1st tax bracket: [0, vec_thr_lo[1]]
2nd tax bracket: (vec_thr_lo[1], vec_thr_lo[2]]
...
(Highest) Nth tax bracket: (vec_thr_lo[length(vec_thr_lo)])

# Returns
- `vec_thr_hi`: Personal income tax bracket upper limits
"""

function upper_thresholds(vec_thr_lo, val=1e5)
    
    vec_thr_hi = vec_thr_lo[2:length(vec_thr_lo)]
    
    push!(vec_thr_hi, val)
    
    return vec_thr_hi
end

"""
    addition(vec_tau, vec_thr_lo)

Computes a vector of "addition" amounts representing the cumulative amounts that a person will pay in income tax if their income exceeds the lowest tax bracket. 
    
Example:
Person A makes \$50,000
vec_thr = [0.08, 0.10]
vec_thr_lo = [\$25,000, \$60,000]
addition = [addition[1], addition[2]], where

addition[1] = 0.08 * \$25,000 = \$2,000
addition[2] = addition[1] + 0.10 * (\$60,000 - \$25,000)

So A would pay \$2,000 + 0.10 * (\$50,000 - \$25,000) = \$4,500

# Returns
- `vec_addition`: Vector of personal income tax "addition" amounts per tax bracket, used to calculate income tax payable
"""

function addition(vec_tau, vec_thr_lo)

    len = length(vec_tau)

    vec_thr_hi = upper_thresholds(vec_thr_lo)

    vec_addition = Vector{Float64}()

    for i = 1:len
        if i == 1
            push!(vec_addition, 0.0)
        else
            last_rate = vec_tau[i-1]
            last_thr_hi = vec_thr_hi[i-1]
            last_thr_lo = vec_thr_lo[i-1]
            last_addition = vec_addition[i-1]
            addition = last_rate * (last_thr_hi - last_thr_lo) + last_addition
            push!(vec_addition, addition)
        end

    end
    return vec_addition
end