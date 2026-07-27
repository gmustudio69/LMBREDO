-- Limit Overdrive - Resonance
local s, id = GetID()
function s.initial_effect(e0)
	-- Activate: Tribute any number of "<Limit Breaker> Kazari" (Monster or S&T Zone), then negate target cards equal to that number
	local e1 = Effect.CreateEffect(e0:GetHandler())
	e1:SetCategory(CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0, TIMINGS_CHECK_MONSTER + TIMING_END_PHASE)
	e1:SetCountLimit(1, id, EFFECT_COUNT_CODE_OATH)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	e0:GetHandler():RegisterEffect(e1)
end

-- Filter for valid tribute targets: "<Limit Breaker> Kazari" on the field (Monster or S&T Zone)
function s.costfilter(c, tp)
	return c:IsFaceup() and c:IsCode(220450) -- Replace 100000000 with "<Limit Breaker> Kazari"'s actual passcode
		and (c:IsLocation(LOCATION_MZONE) or c:IsLocation(LOCATION_SZONE))
		and c:IsReleasable()
		and Duel.IsExistingTarget(s.negfilter, tp, LOCATION_ONBOARD, LOCATION_ONBOARD, 1, c)
end

function s.negfilter(c)
	return c:IsFaceup() and not c:IsDisabled()
end

-- Cost function: Tribute any number of them and store the count to dynamically target cards
function s.cost(e, tp, eg, ep, ev, re, r, rp, chk)
	e:SetLabel(100)
	if chk == 0 then return true end
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		if e:GetLabel() ~= 100 then return false end
		e:SetLabel(0)
		return Duel.CheckReleaseGroupCost(tp, s.costfilter, 1, false, nil, nil, tp)
	end
	e:SetLabel(0)
	
	-- Prompt player to select how many "<Limit Breaker> Kazari" to tribute
	local rg = Duel.SelectReleaseGroupCost(tp, s.costfilter, 1, 99, false, nil, nil, tp)
	local ct = #rg
	Duel.Release(rg,REASON_COST)
	
	-- Save the number tributed so we can target exactly that many cards
	e:SetLabel(ct)
	
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_NEGATE)
	local tg = Duel.SelectTarget(tp, s.negfilter, tp, LOCATION_ONBOARD, LOCATION_ONBOARD, ct, ct, nil)
	Duel.SetOperationInfo(0, CATEGORY_DISABLE, tg, #tg, 0, 0)
end

function s.operation(e, tp, eg, ep, ev, re, r, rp)
	local g = Duel.GetChainInfo(0, CHAININFO_TARGET_CARDS)
	local tg = g:Filter(Card.IsRelateToEffect, nil)
	for tc in aux.Next(tg) do
		if tc:IsFaceup() and not tc:IsDisabled() then
			-- Negate effects
			local e1 = Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESET_EVENT + RESETS_STANDARD)
			tc:RegisterEffect(e1)
			local e2 = Effect.CreateEffect(e:GetHandler())
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			e2:SetReset(RESET_EVENT + RESETS_STANDARD)
			tc:RegisterEffect(e2)
		end
	end
end