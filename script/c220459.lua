--Limit Break - Finale
local s,id=GetID()
function s.initial_effect(c)

--Recycle traps and set
local e1=Effect.CreateEffect(c)
e1:SetCategory(CATEGORY_TODECK+CATEGORY_SET)
e1:SetType(EFFECT_TYPE_QUICK_O)
e1:SetRange(LOCATION_SZONE)
e1:SetCountLimit(1)
e1:SetTarget(s.settg)
e1:SetOperation(s.setop)
c:RegisterEffect(e1)

--Protection effect
local e2=Effect.CreateEffect(c)
e2:SetCategory(CATEGORY_RELEASE)
e2:SetType(EFFECT_TYPE_QUICK_O)
e2:SetRange(LOCATION_SZONE)
e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
e2:SetCountLimit(1,id+1)
e2:SetCost(s.protcost)
e2:SetTarget(s.prottg)
e2:SetOperation(s.protop)
c:RegisterEffect(e2)

end

--Trap recycle filter
function s.tdfilter(c)
return c:IsType(TYPE_TRAP) and c:IsAbleToDeck()
end

function s.synfilter(c)
return c:IsFaceup() and c:IsType(TYPE_SYNCHRO) and c:IsLevel(13)
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
if chkc then return chkc:IsLocation(LOCATION_GRAVE) and s.tdfilter(chkc) end
if chk==0 then
return Duel.IsExistingTarget(s.tdfilter,tp,LOCATION_GRAVE,0,2,nil)
and Duel.IsExistingMatchingCard(Card.IsSSetable,tp,LOCATION_HAND,0,1,nil)
end
Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
local g=Duel.SelectTarget(tp,s.tdfilter,tp,LOCATION_GRAVE,0,2,2,nil)
Duel.SetOperationInfo(0,CATEGORY_TODECK,g,2,0,0)
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
local c=e:GetHandler()
local g=Duel.GetTargetCards(e)
if #g>0 then
Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
end

if Duel.IsExistingMatchingCard(Card.IsSSetable,tp,LOCATION_HAND,0,1,nil)
and Duel.GetLocationCount(tp,LOCATION_SZONE)>0
and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then

Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
local sg=Duel.SelectMatchingCard(tp,Card.IsSSetable,tp,LOCATION_HAND,0,1,1,nil)
local tc=sg:GetFirst()
if tc then
Duel.SSet(tp,tc)

if Duel.IsExistingMatchingCard(s.synfilter,tp,LOCATION_MZONE,0,1,nil) then
local e1=Effect.CreateEffect(c)
e1:SetType(EFFECT_TYPE_SINGLE)
e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
e1:SetReset(RESET_EVENT+RESETS_STANDARD)
tc:RegisterEffect(e1)
end

end
end
end

--Tribute DARK monster cost
function s.cfilter(c)
return c:IsAttribute(ATTRIBUTE_DARK) and c:IsReleasable()
end

function s.protcost(e,tp,eg,ep,ev,re,r,rp,chk)
if chk==0 then return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil) end
Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_MZONE,0,1,1,nil)
Duel.Release(g,REASON_COST)
end

function s.prottg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
if chkc then return chkc:IsOnField() end
if chk==0 then return Duel.IsExistingTarget(Card.IsFaceup,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
local g=Duel.SelectTarget(tp,Card.IsFaceup,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
end

function s.protop(e,tp,eg,ep,ev,re,r,rp)
local tc=Duel.GetFirstTarget()
if tc and tc:IsRelateToEffect(e) then

local e1=Effect.CreateEffect(e:GetHandler())
e1:SetType(EFFECT_TYPE_SINGLE)
e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
e1:SetValue(1)
e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
tc:RegisterEffect(e1)

end
end