-- Limit Overdrive - Resonance
local s, id = GetID()
function s.initial_effect(c)
	-- Activate
	local e1 = Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0, TIMINGS_CHECK_MONSTER + TIMING_END_PHASE)
	e1:SetCountLimit(1, id, EFFECT_COUNT_CODE_OATH)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- Filter for valid tributes: "<Limit Breaker> Kazari" on the field (Monster Zone or face-up Monster treated as Spell)
function s.tribute_filter(c, tp)
	return c:IsFaceup() and c:IsCode(220450)
		and (c:IsLocation(LOCATION_MZONE) or (c:IsLocation(LOCATION_SZONE) and c:IsType(TYPE_MONSTER)))
		and c:IsReleasable()
end

function s.cost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.CheckReleaseGroup(tp, s.tribute_filter, 1, nil, tp) end
	
	-- Let the player choose any number of Kazari cards to tribute
	local rg = Duel.SelectReleaseGroup(tp, s.tribute_filter, 1, 99, nil, tp)
	local ct = #rg
	
	-- Perform the tribute cost
	Duel.Release(rg, REASON_COST)
	
	-- Store the tribute count using SetLabel so target/activation know how many cards to select
	e:SetLabel(ct)
end
s.listed_names={220450,id}
function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
	local ct = e:GetLabel()
	if chk == 0 then return ct > 0 and Duel.IsExistingTarget(Card.IsNegatable, tp, LOCATION_ONBOARD, LOCATION_ONBOARD, ct, nil) end
	
	-- Target cards on the field equal to the number tributed
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DISABLE)
	local g = Duel.SelectTarget(tp, Card.IsNegatable, tp, LOCATION_ONBOARD, LOCATION_ONBOARD, ct, ct, nil)
	Duel.SetOperationInfo(0, CATEGORY_DISABLE, g, ct, 0, 0)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
	local g = Duel.GetChainInfo(0, CHAININFO_TARGET_CARDS)
	if not g then return end
	
	for tc in aux.Next(g) do
		if tc:IsRelateToEffect(e) and tc:IsFaceup() and not tc:IsDisabled() then
			-- Negate effects (permanent or standard depending on design choice; keeping standard persistent negation)
			Duel.NegateRelatedChain(tc, RESET_TURN_SET)
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