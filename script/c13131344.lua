local s,id=GetID()
s.listed_names={13131313}
function s.initial_effect(c)
	-- 1. Activation: Send 1 "Infernal Demon" to GY
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_LIMIT_OATH)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- 2. Anti-Banish: Opponent cannot banish (Action + Activation Lockdown)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_REMOVE)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(0,1)
	c:RegisterEffect(e2)
	
	-- New: Explicitly prevents activation of cards that would banish
	local e2b=Effect.CreateEffect(c)
	e2b:SetType(EFFECT_TYPE_FIELD)
	e2b:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2b:SetCode(EFFECT_CANNOT_ACTIVATE)
	e2b:SetRange(LOCATION_FZONE)
	e2b:SetTargetRange(0,1)
	e2b:SetValue(s.aclimit)
	c:RegisterEffect(e2b)

	-- 3. Stat Boost: +500 ATK/DEF for LIGHT and DARK
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetRange(LOCATION_FZONE)
	e3:SetTargetRange(LOCATION_MZONE,0)
	e3:SetTarget(function(e,c) return c:IsAttribute(ATTRIBUTE_LIGHT) or c:IsAttribute(ATTRIBUTE_DARK) end)
	e3:SetValue(500)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e4)

	-- 4. Attack Restriction: Only LIGHT and DARK can attack
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD)
	e5:SetCode(EFFECT_CANNOT_ATTACK)
	e5:SetRange(LOCATION_FZONE)
	e5:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e5:SetTarget(function(e,c) return not (c:IsAttribute(ATTRIBUTE_LIGHT) or c:IsAttribute(ATTRIBUTE_DARK)) end)
	c:RegisterEffect(e5)

	-- 5. Protection: Unaffected by opponent card effects
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE)
	e6:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e6:SetRange(LOCATION_FZONE)
	e6:SetCode(EFFECT_IMMUNE_EFFECT)
	e6:SetCondition(s.immcon)
	e6:SetValue(function(e,re) return re:GetOwnerPlayer() ~= e:GetHandlerPlayer() end)
	c:RegisterEffect(e6)

	-- 6. Self-Destruct: If MZONE and GY are empty at End Phase
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e7:SetCode(EVENT_PHASE+PHASE_END)
	e7:SetRange(LOCATION_FZONE)
	e7:SetCountLimit(1)
	e7:SetCondition(s.descon)
	e7:SetOperation(s.desop)
	c:RegisterEffect(e7)
end

s.BAYONETTA = 13131313
s.UMBRA_WITCH = 0x8f6
s.INFERNAL_DEMON = 0x704

-- Activation Lockdown Filter
function s.aclimit(e,re,tp)
	-- Checks if the effect being activated involves banishing (category 0x10)
	return re:IsHasCategory(CATEGORY_REMOVE)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(function(c) return c:IsSetCard(s.INFERNAL_DEMON) and c:IsAbleToGrave() end,tp,LOCATION_HAND+LOCATION_DECK,0,nil)
	if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local sg=g:Select(tp,1,1,nil)
		Duel.SendtoGrave(sg,REASON_EFFECT)
	end
end

function s.immcon(e)
	local tp=e:GetHandlerPlayer()
	return Duel.IsExistingMatchingCard(function(c) 
		return c:IsFaceup() and (c:IsCode(s.BAYONETTA) or c:IsSetCard(s.UMBRA_WITCH))
	end,tp,LOCATION_MZONE,0,1,nil)
end

function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetFieldGroupCount(tp,LOCATION_MZONE+LOCATION_GRAVE,0)==0
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Destroy(e:GetHandler(),REASON_EFFECT)
end