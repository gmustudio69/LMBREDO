--Limit Break - Awakening
local s,id=GetID()
function s.initial_effect(c)

--Activate
local e1=Effect.CreateEffect(c)
e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
e1:SetType(EFFECT_TYPE_ACTIVATE)
e1:SetCode(EVENT_FREE_CHAIN)
e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
e1:SetCost(s.cost)
e1:SetTarget(s.target)
e1:SetOperation(s.activate)
c:RegisterEffect(e1)

end

--===== FILTER =====
function s.kzfilter(c)
return c:IsCode(220450) and (c:IsLocation(LOCATION_MZONE) or c:IsFaceup())
end

function s.spfilter(c,e,tp)
return c:IsLevelAbove(7) and c:ListsCode(220450) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SPECIAL,tp,true,true)
end

--===== COST =====
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
	return Duel.IsExistingMatchingCard(s.kzfilter,tp,LOCATION_MZONE+LOCATION_SZONE,0,1,nil)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local g=Duel.SelectMatchingCard(tp,s.kzfilter,tp,LOCATION_MZONE+LOCATION_SZONE,0,1,1,nil)
	local tc=g:GetFirst()

	--If in SZONE → send to GY
	if tc:IsLocation(LOCATION_SZONE) then
	Duel.SendtoGrave(tc,REASON_COST)
	else
	Duel.Release(tc,REASON_COST)
	end
end

--===== TARGET =====
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
	return Duel.GetLocationCountFromEx(tp,tp,nil,nil)>0
	or Duel.GetLocationCount(tp,LOCATION_MZONE)>0
	end

	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_EXTRA)
end

--===== OPERATION =====
function s.activate(e,tp,eg,ep,ev,re,r,rp)

if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK+LOCATION_EXTRA,0,1,1,nil,e,tp)
	local tc=g:GetFirst()

	if tc then
	Duel.SpecialSummon(tc,SUMMON_TYPE_SPECIAL,tp,tp,true,true,POS_FACEUP)
	tc:CompleteProcedure()
	end

end