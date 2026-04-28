local s,id=GetID()
s.listed_names={13131313}
function s.initial_effect(c)
	-- 1. Activation: Send "Infernal Demon" monsters to GY
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_LIMIT_OATH)
	e1:SetTarget(s.tg)
	e1:SetOperation(s.op)
	c:RegisterEffect(e1)

	-- 2. Protection: Cannot be destroyed by card effects
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e2:SetCondition(s.protcon)
	e2:SetValue(1)
	c:RegisterEffect(e2)

	-- 3. Quick Effect: Special Summon 1 "Infernal Demon"
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_SZONE)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e3:SetCountLimit(1)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

s.BAYONETTA = 13131313
s.UMBRA_WITCH = 0x7f6
s.INFERNAL_DEMON = 0x704

-- 1. Send to GY Logic
function s.tgfilter(c)
	return c:IsSetCard(s.INFERNAL_DEMON) and c:IsAbleToGrave()
end
function s.tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
end
function s.op(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local max_ct = Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE) + 1
	local g = Duel.GetMatchingGroup(s.tgfilter,tp,LOCATION_HAND+LOCATION_DECK,0,nil)
	if #g > 0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local sg = aux.SelectUnselectGroup(g,e,tp,1,max_ct,aux.dncheck,1,tp,HINTMSG_TOGRAVE)
		if #sg > 0 then
			Duel.SendtoGrave(sg,REASON_EFFECT)
		end
	end
end

-- 2. Protection Logic
function s.protfilter(c)
	return c:IsFaceup() and (c:IsCode(s.BAYONETTA) or c:IsSetCard(s.UMBRA_WITCH))
end
function s.protcon(e)
	return Duel.IsExistingMatchingCard(s.protfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end

-- 3. Special Summon Logic
function s.spfilter(c,e,tp)
	return c:IsSetCard(s.INFERNAL_DEMON) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) or Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g = Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g > 0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end