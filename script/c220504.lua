--Nocturne Gear - Limit Unyielding Desire
local s,id=GetID()
function s.initial_effect(c)

--Activate
local e1=Effect.CreateEffect(c)
e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND+CATEGORY_HANDES)
e1:SetType(EFFECT_TYPE_ACTIVATE)
e1:SetCode(EVENT_FREE_CHAIN)
e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
e1:SetTarget(s.thtg)
e1:SetOperation(s.thop)
c:RegisterEffect(e1)

--Banish effect
local e2=Effect.CreateEffect(c)
e2:SetCategory(CATEGORY_REMOVE)
e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
e2:SetCode(EVENT_SPSUMMON_SUCCESS)
e2:SetRange(LOCATION_SZONE)
e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
e2:SetCountLimit(1,id+1)
e2:SetCondition(s.rmcon)
e2:SetTarget(s.rmtg)
e2:SetOperation(s.rmop)
c:RegisterEffect(e2)

end

--===== SEARCH =====
function s.thfilter(c)
return c:IsSetCard(0xd8f) and c:IsMonster() and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
if chk==0 then
return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,2,nil)
end
Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,2,tp,LOCATION_DECK)
Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,0,tp,1)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
if Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,2,2,nil)
if #g>0 then
Duel.SendtoHand(g,nil,REASON_EFFECT)
Duel.ConfirmCards(1-tp,g)
end
--discard 1
if Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) then
Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
local dg=Duel.SelectMatchingCard(tp,Card.IsDiscardable,tp,LOCATION_HAND,0,1,1,nil)
if #dg>0 then
Duel.SendtoGrave(dg,REASON_EFFECT+REASON_DISCARD)
end
end
end
end
--===== CONDITION =====
function s.rmfilter(c,tp)
return c:IsFaceup()
and c:IsRace(RACE_PSYCHIC)
and c:IsType(TYPE_SYNCHRO)
and c:IsControler(tp)
end

function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
return eg:IsExists(s.rmfilter,1,nil,tp)
end

--===== TARGET =====
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
if chkc then return chkc:IsOnField() end
if chk==0 then return Duel.IsExistingTarget(Card.IsMonster,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
Duel.SelectTarget(tp,Card.IsMonster,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
end

--===== TEMP BANISH =====
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
local tc=Duel.GetFirstTarget()
if tc and tc:IsRelateToEffect(e) then

Duel.Remove(tc,POS_FACEUP,REASON_EFFECT+REASON_TEMPORARY)

--return at end phase
local e1=Effect.CreateEffect(e:GetHandler())
e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
e1:SetCode(EVENT_PHASE+PHASE_END)
e1:SetReset(RESET_PHASE+PHASE_END)
e1:SetLabelObject(tc)
e1:SetCountLimit(1)
e1:SetOperation(s.retop)
Duel.RegisterEffect(e1,tp)

end
end

function s.retop(e,tp,eg,ep,ev,re,r,rp)
local tc=e:GetLabelObject()
if tc and tc:IsLocation(LOCATION_REMOVED) then
Duel.ReturnToField(tc)
end
end