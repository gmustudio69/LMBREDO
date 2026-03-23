--Argo, The Dark Heterogeneous
local s,id=GetID()
function s.initial_effect(c)

--GY banish summon
local e1=Effect.CreateEffect(c)
e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
e1:SetType(EFFECT_TYPE_IGNITION)
e1:SetRange(LOCATION_GRAVE)
e1:SetCountLimit(1,id)
e1:SetCost(s.spcost)
e1:SetTarget(s.sptg)
e1:SetOperation(s.spop)
c:RegisterEffect(e1)

end

--Cost
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
if chk==0 then return e:GetHandler():IsAbleToRemoveAsCost() end
Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end

--Summon filter
function s.spfilter(c,e,tp)
return c:IsAttribute(ATTRIBUTE_DARK)
and c:IsRace(RACE_WARRIOR)
and (c:IsLevel(6) or c:IsLevel(7))
and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
if chk==0 then
return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,e,tp)
end
Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,e,tp)
if #g>0 then
Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
end
end