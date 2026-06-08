--<Limit Breaker> Ouroboros
local s,id,o=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()

	-- must be special summoned by "Limit" effect
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)
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
	-- Gain effects if you control Ellie
	---------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_ADJUST)
	e2:SetCondition(s.elliecon)
	e2:SetOperation(s.ellieop)
	c:RegisterEffect(e2)
end
function s.splimit(e,se,sp,st)
	return se and se:IsHasType(EFFECT_TYPE_ACTIONS)
		and se:GetHandler():IsSetCard(0xf86)
end

---------------------------------------------------
-- MATERIAL ATTACH EFFECT
---------------------------------------------------
function s.matfilter(c,tp)
	return c:IsPreviousLocation(LOCATION_ONFIELD)
		and c:IsPreviousControler(1-tp)
		and c:IsBanished()
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

	for tc in aux.Next(g) do
		if tc:IsLocation(LOCATION_REMOVED) and tc:IsFaceup() then
			Duel.Overlay(c,Group.FromCards(tc))
		end
	end
end

---------------------------------------------------
-- CHECK ELLIE CONTROL
---------------------------------------------------
function s.elliecon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_ONFIELD,0,1,nil,220405)
end

function s.ellieop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	---------------------------------------------------
	-- Effect 1: replacement banish instead of send/detach
	---------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_TO_GRAVE_REDIRECT)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_ONFIELD,LOCATION_ONFIELD)
	e1:SetValue(LOCATION_REMOVED)
	e1:SetCondition(s.elliecon)
	c:RegisterEffect(e1)

	---------------------------------------------------
	-- Effect 2: Quick detach → copy Limit spell
	---------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e2:SetCost(s.copycost)
	e2:SetTarget(s.copytg)
	e2:SetOperation(s.copyop)
	c:RegisterEffect(e2)
end

---------------------------------------------------
-- COPY LIMIT SPELL COST
---------------------------------------------------
function s.limitspellfilter(c)
	return c:IsSetCard(0xf86)
		and c:IsSpell()
		and c:IsAbleToRemoveAsCost()
end

function s.copycost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return c:IsType(TYPE_XYZ)
			and c:GetOverlayCount()>=2
			and Duel.IsExistingMatchingCard(s.limitspellfilter,tp,LOCATION_GRAVE,0,1,nil)
	end

	c:RemoveOverlayCard(tp,2,2,REASON_COST)
end

function s.copytg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chk==0 then return true end
end

function s.copyop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)

	local g=Duel.SelectMatchingCard(tp,s.limitspellfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	local tc=g:GetFirst()

	if not tc then return end

	Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)

	local ce=tc:CopyEffect(id,RESET_EVENT+RESETS_STANDARD)

	if ce then
		ce:SetOwnerPlayer(tp)
	end
end