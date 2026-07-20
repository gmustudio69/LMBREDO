-- Custom Card ID (Change this to match your text file name)
local s,id = GetID()
function s.initial_effect(c)
	-- Xyz Summon Procedure
	Xyz.AddProcedure(c,nil,4,2,s.xyzfilter,aux.Stringid(id,0),nil,s.xyzop)
	c:EnableReviveLimit()
	
	 local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_TO_GRAVE_REDIRECT)
	e0:SetRange(LOCATION_MZONE)
	e0:SetTarget(s.rmtarget)
	e0:SetTargetRange(LOCATION_ALL,LOCATION_ALL)
	e0:SetValue(LOCATION_HAND)
	c:RegisterEffect(e0)
	
	-- Ignition Effect: Detach to destroy 1 FIRE from Deck/Field, then optional pop
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1, id)
	e2:SetCost(Cost.DetachFromSelf(1))
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
	
	-- Trigger Effect: If destroyed by card effect, Special Summon from hand
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetCountLimit(1, id + 1)
	e3:SetCondition(s.spcon)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
	
	--Register destruction of monsters
	aux.GlobalCheck(s,function()
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_DESTROY)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)
	end)
end

function s.checkfilter(c)
	return (c:IsPreviousLocation(LOCATION_MZONE) or (c:IsMonster() and not c:IsPreviousLocation(LOCATION_ONFIELD))) and c:IsReason(REASON_EFFECT)
end
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	local g=eg:Filter(s.checkfilter,nil)
	if #g==0 then return end
	for p=0,1 do
		if g:IsExists(Card.IsPreviousControler,1,nil,p) and not Duel.HasFlagEffect(p,id) then
			Duel.RegisterFlagEffect(p,id,RESET_PHASE|PHASE_END,0,1)
		end
	end
end

function s.xyzfilter(c,tp,xyzc)
	return c:IsFaceup() and c:IsSetCard(0xc25) and not c:IsType(TYPE_XYZ)
end
function s.xyzop(e,tp,chk)
	if chk==0 then return Duel.GetFlagEffect(tp,id)==0 and
		Duel.GetCustomActivityCount(id,tp,ACTIVITY_CHAIN)>0 end
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,EFFECT_FLAG_OATH,1)
	return true
end

function s.rmtarget(e,c)
	return c:IsReason(REASON_DESTROY)
end

-- 3. Detach, Destroy 1 FIRE from Deck/Field, then pop 1
function s.desfilter(c)
	return c:IsAttribute(ATTRIBUTE_FIRE) and (c:IsLocation(LOCATION_DECK) or c:IsFaceup()
end
function s.destg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsExistingMatchingCard(s.desfilter, tp, LOCATION_DECK + LOCATION_MZONE, 0, 1, nil) end
	Duel.SetOperationInfo(0, CATEGORY_DESTROY, nil, 1, tp, LOCATION_DECK + LOCATION_MZONE)
end
function s.desop(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
	local g = Duel.SelectMatchingCard(tp,s.desfilter, tp,LOCATION_DECK +LOCATION_MZONE, 0, 1, 1, nil)
	if #g > 0 and Duel.Destroy(g, REASON_EFFECT) > 0 then
		if Duel.IsExistingMatchingCard(nil, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, nil) 
		   and Duel.SelectYesNo(tp, aux.Stringid(id, 3)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
			local sg = Duel.SelectMatchingCard(tp, nil, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, 1, nil)
			if #sg > 0 then
				Duel.HintSelection(sg)
				Duel.Destroy(sg,REASON_EFFECT)
			end
		end
	end
end

-- 4. Float on Destruction Logic
function s.spcon(e, tp, eg, ep, ev, re, r, rp)
	return (r & REASON_EFFECT) ~= 0
end
function s.spfilter(c,e,tp)
	return c:IsAttribute(ATTRIBUTE_FIRE) and c:IsLevelBelow(7) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end
function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
		and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND, 0, 1, nil, e, tp) end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND)
end
function s.spop(e, tp, eg, ep, ev, re, r, rp)
	if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local g = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND, 0, 1, 1, nil, e, tp)
	if #g > 0 then
		Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
	end
end