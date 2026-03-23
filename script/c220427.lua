--Aerys, Angel of the Endless
local s,id=GetID()

function s.initial_effect(c)

	--Synchro summon
	Synchro.AddProcedure(c,aux.FilterBoolFunction(Card.IsAttribute,ATTRIBUTE_DARK),1,1,Synchro.NonTuner(nil),1,99)
	c:EnableReviveLimit()

	--Cannot attack the turn it is summoned
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_CANNOT_ATTACK)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e0:SetCondition(s.atkcon)
	c:RegisterEffect(e0)

	--Search "Limit" Counter Trap
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	--Opponent Special Summon trigger
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,id+1)
	e2:SetCondition(s.drcon)
	e2:SetTarget(s.drtg)
	e2:SetOperation(s.drop)
	c:RegisterEffect(e2)

end

--Cannot attack condition
function s.atkcon(e)
local c=e:GetHandler()
return c:GetTurnID()==Duel.GetTurnCount()
end

--Search filter
function s.thfilter(c)
	return c:IsType(TYPE_COUNTER) and c:IsType(TYPE_TRAP) and c:IsSetCard(0xf86) and c:IsAbleToHand()
end
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
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

--Opponent Special Summon condition
function s.drcon(e,tp,eg,ep,ev,re,r,rp)
return eg:IsExists(Card.IsControler,1,nil,1-tp)
end

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
if chkc then return eg:IsContains(chkc) end
if chk==0 then return eg:IsExists(Card.IsControler,1,nil,1-tp) end

Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
local g=eg:FilterSelect(tp,Card.IsControler,1,1,nil,1-tp)
Duel.SetTargetCard(g)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end

	local attr=tc:GetOriginalAttribute()
	local typ=tc:GetOriginalType()

	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetReset(RESET_PHASE+PHASE_END)
	e1:SetOperation(function(e,tp,eg,ep,ev,re,r,rp)
		local g=eg:Filter(function(c)
			return c:GetOriginalAttribute()==attr or (c:GetOriginalType()&typ)>0
		end,nil)
		if #g>0 then
			Duel.Draw(tp,#g,REASON_EFFECT)
		end
	end)
	Duel.RegisterEffect(e1,tp)
end