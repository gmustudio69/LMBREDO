--Limit Break - Eradicate
local s,id=GetID()
function s.initial_effect(c)
	-- Destroy / Banish FD
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- Send 1 "World Decoder" to GY when this sent to GY
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.tgtg)
	e2:SetOperation(s.tgop)
	c:RegisterEffect(e2)
end

function s.lbreakerfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xf86) -- "Limit Breaker"
end
function s.targetfilter(c)
	return c:IsDestructable()
end
function s.elliefilter(c)
	return c:IsFaceup() and c:IsCode(220405) -- Update with your <World Decoder> Ellie card ID
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and s.targetfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.targetfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
	local ct=Duel.GetMatchingGroupCount(s.lbreakerfilter,tp,LOCATION_MZONE,0,nil)+1
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,s.targetfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,ct,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	local ct=#g
	if ct==0 then return end
	local ellie=Duel.IsExistingMatchingCard(s.elliefilter,tp,LOCATION_ONFIELD,0,1,nil)
	if ellie and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		for tc in aux.Next(g) do
			if tc:IsRelateToEffect(e) then
				Duel.Remove(tc,POS_FACEDOWN,REASON_EFFECT)
			end
		end
	else
		Duel.Destroy(g,REASON_EFFECT)
	end
end

function s.tgfilter(c)
	return c:IsSetCard(0xb67) and c:IsType(TYPE_MONSTER) and c:IsAbleToGrave()
end
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)

end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoGrave(g,REASON_EFFECT)
	end
end
