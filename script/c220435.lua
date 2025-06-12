-- Counter Trap: "Your Card Name"
local s,id=GetID()
function s.initial_effect(c)
	-- Activate effect: Negate Summon and possibly Special Summon
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DISABLE_SUMMON+CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_SPSUMMON)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(aux.NegateSummonCondition)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- Check if a Level 13 Synchro is on the field
function s.filter1(c)
	return c:IsType(TYPE_SYNCHRO) and c:IsLevel(13)
end

-- Check if a controlled "L:B" Xyz Monster has materials to detach
function s.filter2(c)
	return c:IsType(TYPE_XYZ) and c:IsSetCard(0xf86) and c:CheckRemoveOverlayCard(tp,1,REASON_COST)
end

-- Cost: Detach 1 material from an "L:B" Xyz OR If Level 13 Synchro is present, no detachment needed
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	local b1=Duel.IsExistingMatchingCard(s.filter1,tp,LOCATION_MZONE,0,1,nil)
	local b2=Duel.IsExistingMatchingCard(s.filter2,tp,LOCATION_MZONE,0,1,nil)
	if chk==0 then return b1 or b2 end
	if b1 then
		if b2 and not Duel.SelectYesNo(tp,aux.Stringid(id,0)) then return end
		local tc = Duel.SelectMatchingCard(tp,s.filter1,tp,LOCATION_MZONE,0,1,1,nil):GetFirst()
		if tc then
			tc:RemoveOverlayCard(tp,1,1,REASON_COST)
		end
	end
end

-- Targeting: Confirm negation & destruction
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_DISABLE_SUMMON,eg,eg:GetCount(),0,0)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,eg:GetCount(),0,0)
end
-- Operation: Negate Summon, Destroy, and Special Summon (if conditions met)
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	Duel.NegateSummon(eg)
	if Duel.Destroy(eg,REASON_EFFECT)>0 and Duel.IsExistingMatchingCard(s.filter1,tp,LOCATION_MZONE,0,1,nil) then
		-- If Level 13 Synchro is on the field, allow Special Summon from GY
		Duel.BreakEffect()
		local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end

-- Filter for Special Summon: DARK Warrior from GY
function s.spfilter(c,e,tp)
	return c:IsAttribute(ATTRIBUTE_DARK) and c:IsRace(RACE_WARRIOR) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
