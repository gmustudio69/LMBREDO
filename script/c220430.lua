--Limit Break - Oblivion
local s,id=GetID()
function s.initial_effect(c)
	-- Banish opponent's GY cards (face-down if Ellie)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.rmtg)
	e1:SetOperation(s.rmop)
	c:RegisterEffect(e1)

	-- GY Effect: attach top-deck card to Limit Breaker Xyz
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.mttg)
	e2:SetOperation(s.mtop)
	c:RegisterEffect(e2)
end

-- Check for "Limit Breaker" monster count
function s.lbcfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xf86) -- "Limit Breaker"
end

-- Check for "World Decoder Ellie"
function s.elliefilter(c)
	return c:IsFaceup() and c:IsCode(220405) -- replace with actual code
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local ct=Duel.GetMatchingGroupCount(s.lbcfilter,tp,LOCATION_MZONE,0,nil)+1
	if chk==0 then
		return Duel.IsExistingMatchingCard(Card.IsAbleToRemove,tp,0,LOCATION_GRAVE,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectTarget(tp,Card.IsAbleToRemove,tp,0,LOCATION_GRAVE,1,ct,nil)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,#g,1-tp,LOCATION_GRAVE)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g==0 then return end
	local ellie=Duel.IsExistingMatchingCard(s.elliefilter,tp,LOCATION_ONFIELD,0,1,nil)
	if ellie and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		Duel.Remove(g,POS_FACEDOWN,REASON_EFFECT)
	else
		Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
	end
end

-- GY Effect: attach opponent's top deck to "Limit Breaker" Xyz as material
function s.xyzfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_XYZ) and c:IsSetCard(0xf86)
end

function s.mttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_MZONE,0,1,nil)
			and Duel.GetFieldGroupCount(1-tp,LOCATION_DECK,0)>0
	end
end

function s.mtop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.xyzfilter,tp,LOCATION_MZONE,0,nil)
	if #g==0 or Duel.GetFieldGroupCount(1-tp,LOCATION_DECK,0)==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local tc=g:Select(tp,1,1,nil):GetFirst()
	local top=Duel.GetDecktopGroup(1-tp,1)
	local card=top:GetFirst()
	if tc and card then
		Duel.DisableShuffleCheck()
		Duel.Overlay(tc,top)
	end
end
