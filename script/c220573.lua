--<Limit Breaker> Seraphim
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()

	-- Must be Special Summoned by a "Limit" Spell/Trap effect
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)

	-- Cannot be destroyed by card effects
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	-- If Special Summoned: Negate all opponent's currently activated effects (Does NOT start a chain)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)

	-- Quick Effect (Opponent activates a card/effect & has "Limit Break - Install!!!" as material): Rank-Up Xyz
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id)
	e3:SetCondition(s.xyzcon)
	e3:SetTarget(s.xyztg)
	e3:SetOperation(s.xyzop)
	c:RegisterEffect(e3)

	-- Detach 1: Banish up to 2 cards on the field and/or GY
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_REMOVE)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id+100)
	e4:SetCost(Cost.DetachFromSelf(2))
	e4:SetTarget(s.rmtg)
	e4:SetOperation(s.rmop)
	c:RegisterEffect(e4)
end

-- ==========================================
-- Definitions & Constants
-- ==========================================
local SET_LIMIT = 0xf86			   -- Replace with your "Limit" S/T archetype setcode
local SET_LIMIT_BREAKER = 0xf86	   -- Replace with your "Limit Breaker" archetype setcode
local CARD_INSTALL = 220407		 -- Replace with exact ID of "Limit Break - Install!!!"

-- Must be Special Summoned by "Limit" S/T
function s.splimit(e,se,sp,st)
	return se and se:IsHasType(EFFECT_TYPE_ACTIONS) 
		and se:GetHandler():IsSetCard(SET_LIMIT) 
		and (se:GetHandler():IsType(TYPE_SPELL) or se:GetHandler():IsType(TYPE_TRAP))
end

-- ==========================================
-- E2: Negate Opponent Activated Effects
-- ==========================================
-- ==========================================
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local chain_length = Duel.GetCurrentChain()
	if chain_length == 0 then return end
	
	for i = 1, chain_length do
		local p = Duel.GetChainInfo(i, CHAININFO_TRIGGERING_PLAYER)
		if p == 1-tp then
			Duel.NegateEffect(i)
		end
	end
end

function s.distg(e,c)
	return c:IsStatus(STATUS_DISABLED) or c:IsType(TYPE_EFFECT)
end

-- ==========================================
-- E3: Quick Effect Xyz Overlay
-- ==========================================
function s.xyzcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return rp==1-tp and c:GetOverlayGroup():IsExists(Card.IsCode,1,nil,CARD_INSTALL)
end

function s.xyzfilter(c,e,tp,mc)
	return c:IsSetCard(SET_LIMIT_BREAKER) and c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsType(TYPE_XYZ)
		and not c:IsCode(id)
		and mc:IsCanBeXyzMaterial(c)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
		and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0
end

function s.xyztg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,c) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.xyzop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFacedown() or not c:IsRelateToEffect(e) or c:IsControler(1-tp) or c:IsImmuneToEffect(e) then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,c)
	local sc=g:GetFirst()
	if sc then
		local mg=c:GetOverlayGroup()
		if #mg>0 then
			Duel.Overlay(sc,mg)
		end
		sc:SetMaterial(Group.FromCards(c))
		Duel.Overlay(sc,Group.FromCards(c))
		Duel.SpecialSummon(sc,SUMMON_TYPE_XYZ,tp,tp,true,true,POS_FACEUP)
		sc:CompleteProcedure()
	end
end

-- ==========================================
-- E4: Banish up to 2 Cards (Field / GY)
-- ==========================================
function s.rmfilter(c)
	return (c:IsOnField() or c:IsLocation(LOCATION_GRAVE)) and c:IsAbleToRemove()
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_ONFIELD|LOCATION_GRAVE) and s.rmfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.rmfilter,tp,LOCATION_ONFIELD|LOCATION_GRAVE,LOCATION_ONFIELD|LOCATION_GRAVE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectTarget(tp,s.rmfilter,tp,LOCATION_ONFIELD|LOCATION_GRAVE,LOCATION_ONFIELD|LOCATION_GRAVE,1,2,nil)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,#g,0,0)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g>0 then
		Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
	end
end