-- Pyrea ??? (Rank 13)
local s,id=GetID()

function s.initial_effect(c)
	-- Xyz Summon
	Xyz.AddProcedure(c,nil,13,3)
	c:EnableReviveLimit()

	-------------------------------------------------
	-- Cannot leave the field while face-up
	-------------------------------------------------

	-- Cannot be sent to GY
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.faceupcon)
	e1:SetCode(EFFECT_CANNOT_TO_GRAVE)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	-- Cannot be banished
	local e2=e1:Clone()
	e2:SetCode(EFFECT_CANNOT_REMOVE)
	c:RegisterEffect(e2)

	-- Cannot return to hand
	local e3=e1:Clone()
	e3:SetCode(EFFECT_CANNOT_TO_HAND)
	c:RegisterEffect(e3)

	-- Cannot return to Deck/Extra
	local e4=e1:Clone()
	e4:SetCode(EFFECT_CANNOT_TO_DECK)
	c:RegisterEffect(e4)

	-- Cannot change control
	local e5=e1:Clone()
	e5:SetCode(EFFECT_CANNOT_CHANGE_CONTROL)
	c:RegisterEffect(e5)

	-- Cannot be Tributed
	local e6=e1:Clone()
	e6:SetCode(EFFECT_UNRELEASABLE_SUM)
	c:RegisterEffect(e6)

	local e7=e6:Clone()
	e7:SetCode(EFFECT_UNRELEASABLE_NONSUM)
	c:RegisterEffect(e7)

	-- Cannot be used as Fusion Material
	local e8=e1:Clone()
	e8:SetCode(EFFECT_CANNOT_BE_FUSION_MATERIAL)
	e8:SetValue(1)
	c:RegisterEffect(e8)

	-- Cannot be used as Synchro Material
	local e9=e1:Clone()
	e9:SetCode(EFFECT_CANNOT_BE_SYNCHRO_MATERIAL)
	e9:SetValue(1)
	c:RegisterEffect(e9)

	-- Cannot be used as Link Material
	local e10=e1:Clone()
	e10:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
	e10:SetValue(1)
	c:RegisterEffect(e10)

	-- Cannot be used as Ritual Material
	local e11=e1:Clone()
	e11:SetCode(EFFECT_CANNOT_RELEASE)
	e11:SetValue(1)
	c:RegisterEffect(e11)
	-- Cannot be destroyed by battle
	local e12=Effect.CreateEffect(c)
	e12:SetType(EFFECT_TYPE_SINGLE)
	e12:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e12:SetRange(LOCATION_MZONE)
	e12:SetCondition(s.faceupcon)
	e12:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e12:SetValue(1)
	c:RegisterEffect(e12)

	-- Cannot be destroyed by card effects
	local e13=e12:Clone()
	e13:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e13:SetValue(1)
	c:RegisterEffect(e13)

	-------------------------------------------------
	-- Quick Effect
	-------------------------------------------------
	local e99=Effect.CreateEffect(c)
	e99:SetDescription(aux.Stringid(id,0))
	e99:SetCategory(CATEGORY_REMOVE)
	e99:SetType(EFFECT_TYPE_QUICK_O)
	e99:SetCode(EVENT_FREE_CHAIN)
	e99:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e99:SetRange(LOCATION_MZONE)
	e99:SetCost(s.rmcost)
	e99:SetTarget(s.rmtg)
	e99:SetOperation(s.rmop)
	c:RegisterEffect(e99)
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