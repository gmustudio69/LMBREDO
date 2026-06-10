-- Blastcore Detonator
local s,id=GetID()

function s.initial_effect(c)


	---------------------------------------------------
	-- Replacement: destroyed cards to GY → hand
	---------------------------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_TO_GRAVE_REDIRECT)
	e0:SetRange(LOCATION_MZONE)
	e0:SetTarget(s.rmtarget)
	e0:SetTargetRange(LOCATION_ALL,LOCATION_ALL)
	e0:SetValue(LOCATION_HAND)
	c:RegisterEffect(e0)

	---------------------------------------------------
	-- Summon effect
	---------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)

	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)

	---------------------------------------------------
	-- Revive + Deck summon on destruction
	---------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.revcon)
	e3:SetOperation(s.revop)
	c:RegisterEffect(e3)

end

---------------------------------------------------
-- REPLACEMENT: destroy → add to hand
---------------------------------------------------
function s.rmtarget(e,c)
	return c:IsReason(REASON_DESTROY)
end

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return eg:IsExists(s.repfilter,1,nil)
	end
	return true
end

function s.repval(e,c)
	return s.repfilter(c)
end

---------------------------------------------------
-- DESTROY EFFECT FILTERS
---------------------------------------------------
function s.desfilter(c)
	return (c:IsSetCard(0xc25) and c:IsMonster())
		or (c:IsAttribute(ATTRIBUTE_FIRE) and c:IsRace(RACE_WARRIOR) and c:IsLevel(7))
end

---------------------------------------------------
-- DESTROY TARGET
---------------------------------------------------
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.desfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
end

---------------------------------------------------
-- DESTROY OPERATION
---------------------------------------------------
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)

	local g=Duel.SelectMatchingCard(tp,s.desfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil)
	local tc=g:GetFirst()

	if tc then
		Duel.Destroy(tc,REASON_EFFECT)
	end
end

---------------------------------------------------
-- REVIVE AFTER DESTRUCTION
---------------------------------------------------
function s.revcon(e,tp,eg,ep,ev,re,r,rp)
	return r&REASON_EFFECT~=0
end

--Register Battle Phase revive
function s.revop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	local loc=c:GetLocation()

	-- store original location zone
	e:SetLabel(loc)
	e:SetLabelObject(c)

	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PHASE+PHASE_BATTLE_START)
	e1:SetCountLimit(1)
	e1:SetLabel(loc)
	e1:SetLabelObject(c)
	e1:SetOperation(s.revsp)
	e1:SetReset(RESET_PHASE+PHASE_BATTLE)
	Duel.RegisterEffect(e1,tp)
end

function s.revsp(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetLabelObject()
	local loc=e:GetLabel()
	if c and c:IsLocation(loc)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end