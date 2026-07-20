-- Pyrea ??? (Rank 13)
local s,id=GetID()

function s.initial_effect(c)
	-- Xyz Summon
	Xyz.AddProcedure(c,nil,13,3)
	c:EnableReviveLimit()

	-------------------------------------------------
	-- Cannot leave the field while face-up
	-------------------------------------------------

	-- Cannot be returned to hand
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_CANNOT_TO_HAND)
	e1:SetCondition(s.faceupcon)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	-- Cannot be returned to Deck
	local e2=e1:Clone()
	e2:SetCode(EFFECT_CANNOT_TO_DECK)
	c:RegisterEffect(e2)

	-- Cannot be banished
	local e3=e1:Clone()
	e3:SetCode(EFFECT_CANNOT_REMOVE)
	c:RegisterEffect(e3)

	-- Cannot be sent to GY
	local e4=e1:Clone()
	e4:SetCode(EFFECT_CANNOT_TO_GRAVE)
	c:RegisterEffect(e4)

	-- Cannot be released
	local e5=e1:Clone()
	e5:SetCode(EFFECT_UNRELEASABLE_SUM)
	c:RegisterEffect(e5)

	local e6=e5:Clone()
	e6:SetCode(EFFECT_UNRELEASABLE_NONSUM)
	c:RegisterEffect(e6)

	-- Cannot change control
	local e7=e1:Clone()
	e7:SetCode(EFFECT_CANNOT_CHANGE_CONTROL)
	c:RegisterEffect(e7)

	-------------------------------------------------
	-- Quick Effect
	-------------------------------------------------
	local e8=Effect.CreateEffect(c)
	e8:SetDescription(aux.Stringid(id,0))
	e8:SetCategory(CATEGORY_REMOVE)
	e8:SetType(EFFECT_TYPE_QUICK_O)
	e8:SetCode(EVENT_FREE_CHAIN)
	e8:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e8:SetRange(LOCATION_MZONE)
	e8:SetCountLimit(1,id)
	e8:SetCost(s.rmcost)
	e8:SetTarget(s.rmtg)
	e8:SetOperation(s.rmop)
	c:RegisterEffect(e8)
end

-------------------------------------------------
-- Only while face-up
-------------------------------------------------

function s.faceupcon(e)
	return e:GetHandler():IsFaceup()
end

-------------------------------------------------
-- Quick Effect
-------------------------------------------------

function s.rmcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return e:GetHandler():CheckRemoveOverlayCard(tp,2,REASON_COST)
	end
	e:GetHandler():RemoveOverlayCard(tp,2,2,REASON_COST)
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,nil)
	if chk==0 then return #g>0 end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,#g,0,0)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,nil)
	if #g>0 then
		Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
	end
end