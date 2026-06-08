-- Custom Xyz Monster (Limit / Ellie synergy)
local s,id=GetID()

local ELLIE_CODE=220405 -- replace with real code

function s.initial_effect(c)

	c:EnableReviveLimit()

	---------------------------------------------------
	-- Must be summoned by "Limit" effect
	---------------------------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)

	---------------------------------------------------
	-- Attach opponent banished cards as material
	---------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_REMOVE)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.matcon)
	e1:SetTarget(s.mattg)
	e1:SetOperation(s.matop)
	c:RegisterEffect(e1)

	---------------------------------------------------
	-- Effect 1: replace sends/detach → banish (requires Ellie)
	---------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_TO_GRAVE_REDIRECT)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_ONFIELD,LOCATION_ONFIELD)
	e2:SetValue(LOCATION_REMOVED)
	e2:SetCondition(s.elcon)
	c:RegisterEffect(e2)

	---------------------------------------------------
	-- Effect 2: Quick Effect (detach 2 → copy Limit Spell)
	---------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.elcon)
	e3:SetCost(s.copycost)
	e3:SetTarget(s.copytg)
	e3:SetOperation(s.copyop)
	c:RegisterEffect(e3)

end

---------------------------------------------------
-- SUMMON LIMIT (must be Limit effect)
---------------------------------------------------
function s.splimit(e,se,sp,st)
	return se and se:IsHasType(EFFECT_TYPE_ACTIONS)
		and se:GetHandler()
		and se:GetHandler():IsSetCard(0xf86)
end

---------------------------------------------------
-- MATERIAL ATTACH
---------------------------------------------------
function s.matfilter(c,tp)
	return c:IsPreviousLocation(LOCATION_ONFIELD)
		and c:IsPreviousControler(1-tp)
		and c:IsType(TYPE_MONSTER+TYPE_SPELL+TYPE_TRAP)
end

function s.matcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.matfilter,1,nil,tp)
end

function s.mattg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end

function s.matop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=eg:Filter(s.matfilter,nil,tp)

	if #g>0 then
		Duel.Overlay(c,g)
	end
end

---------------------------------------------------
-- CHECK ELLIE ON FIELD
---------------------------------------------------
function s.elcon(e)
	return Duel.IsExistingMatchingCard(Card.IsCode,e:GetHandlerPlayer(),LOCATION_ONFIELD,0,1,nil,ELLIE_CODE)
end

---------------------------------------------------
-- QUICK EFFECT COST
---------------------------------------------------
function s.limitfilter(c)
	return c:IsSetCard(0xf86)
		and c:IsSpell()
		and c:IsAbleToRemoveAsCost()
end

function s.copycost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsType(TYPE_XYZ)
			and c:GetOverlayCount()>=2
			and Duel.IsExistingMatchingCard(s.limitfilter,tp,LOCATION_GRAVE,0,1,nil)
	end

	c:RemoveOverlayCard(tp,2,2,REASON_COST)
end

function s.copytg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end

---------------------------------------------------
-- QUICK EFFECT OPERATION
---------------------------------------------------
function s.copyop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)

	local g=Duel.SelectMatchingCard(tp,s.limitfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	local tc=g:GetFirst()

	if not tc then return end

	Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)

	local ce=tc:CopyEffect(id,RESET_EVENT+RESETS_STANDARD)

	if ce then
		ce:SetOwnerPlayer(tp)
	end
end