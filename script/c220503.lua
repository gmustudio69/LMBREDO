--Nocturne Gear - Glitch
local s,id=GetID()
function s.initial_effect(c)

--Discard to search
local e1=Effect.CreateEffect(c)
e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
e1:SetType(EFFECT_TYPE_IGNITION)
e1:SetRange(LOCATION_HAND)
e1:SetCountLimit(1,id)
e1:SetCost(s.thcost)
e1:SetTarget(s.thtg)
e1:SetOperation(s.thop)
c:RegisterEffect(e1)

--Special summon effect
local e2=Effect.CreateEffect(c)
e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DAMAGE)
e2:SetType(EFFECT_TYPE_IGNITION)
e2:SetRange(LOCATION_HAND+LOCATION_GRAVE)
e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
e2:SetCountLimit(1,id+1)
e2:SetTarget(s.sptg)
e2:SetOperation(s.spop)
c:RegisterEffect(e2)

end

--===== COST =====
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
if chk==0 then return e:GetHandler():IsDiscardable() end
Duel.SendtoGrave(e:GetHandler(),REASON_COST+REASON_DISCARD)
end

--===== SEARCH =====
function s.thfilter(c)
return (c:IsSetCard(0xd8f) and c:IsType(TYPE_SPELL+TYPE_TRAP))
or (c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsRace(RACE_PSYCHIC) and c:IsMonster())
and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
if chk==0 then
return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
end
Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
if #g>0 then
Duel.SendtoHand(g,nil,REASON_EFFECT)
Duel.ConfirmCards(1-tp,g)
end
end

--===== SPECIAL SUMMON =====
function s.psyfilter(c)
return c:IsFaceup() and c:IsRace(RACE_PSYCHIC)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.psyfilter(chkc) end
if chk==0 then
return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
and Duel.IsExistingTarget(s.psyfilter,tp,LOCATION_MZONE,0,1,nil)
and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false)
end
Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
Duel.SelectTarget(tp,s.psyfilter,tp,LOCATION_MZONE,0,1,1,nil)
Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,tp,0)
Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
local c=e:GetHandler()
local tc=Duel.GetFirstTarget()

if not tc or not tc:IsRelateToEffect(e) then return end

local lv=tc:GetLevel()
if lv<=0 then return end

Duel.Damage(tp,lv*100,REASON_EFFECT)

if c:IsRelateToEffect(e) then
Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
end
end