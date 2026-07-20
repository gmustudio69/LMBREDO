--Detonator Payload Carrier
local s,id,o=GetID()
function s.initial_effect(c)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_TO_GRAVE_REDIRECT)
	e0:SetRange(LOCATION_MZONE)
	e0:SetTarget(s.rmtarget)
	e0:SetTargetRange(LOCATION_ALL,LOCATION_ALL)
	e0:SetValue(LOCATION_HAND)
	c:RegisterEffect(e0)
	--On Normal or Special Summon: Destroy 1 "Pyrea" Spell, then SpSummon 1 FIRE monster with 0 DEF
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
	local e2_sp=e2:Clone()
	e2_sp:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2_sp)

	--If destroyed by card effect: Special Summon this card
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetCountLimit(1,id+100)
	e3:SetCondition(s.spcon1)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
	
	--If added to hand except by drawing: Special Summon this card
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_TO_HAND)
	e4:SetCountLimit(1,id+100)
	e4:SetCondition(s.spcon2)
	e4:SetTarget(s.sptg)
	e4:SetOperation(s.spop)
	c:RegisterEffect(e4)
end
---------------------------------------------------
-- REPLACEMENT: destroy → add to hand
---------------------------------------------------
function s.rmtarget(e,c)
	return c:IsReason(REASON_DESTROY) and c:IsReason(REASON_EFFECT)
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
-- 2. Summon Trigger Functions
function s.desfilter(c)
	return c:IsSetCard(0x989) and c:IsType(TYPE_SPELL) and c:IsDestructable()
		and (c:IsLocation(LOCATION_HAND|LOCATION_DECK) or c:IsFaceup())
end

function s.spfilter(c,e,tp)
	return c:IsAttribute(ATTRIBUTE_FIRE) and c:IsDefense(0)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.desfilter,tp,LOCATION_HAND|LOCATION_DECK|LOCATION_ONFIELD,0,1,nil) 
	end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_HAND|LOCATION_DECK|LOCATION_ONFIELD)
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,s.desfilter,tp,LOCATION_HAND|LOCATION_DECK|LOCATION_ONFIELD,0,1,1,nil)
	if #g>0 and Duel.Destroy(g,REASON_EFFECT)>0 then
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
		local sg=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_HAND,0,nil,e,tp)
		if #sg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local sc=sg:Select(tp,1,1,nil)
			Duel.SpecialSummon(sc,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end

-- 3. Self-Special Summon Trigger Functions
function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
	return (r&REASON_EFFECT)~=0
end

function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- Filter out normal draw phases/card effect draws
	return c:IsPreviousLocation(LOCATION_DECK|LOCATION_GRAVE|LOCATION_REMOVED|LOCATION_ONFIELD) 
		and not (re and re:IsHasCategory(CATEGORY_DRAW))
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then 
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false) 
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end