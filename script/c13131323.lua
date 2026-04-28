local s,id=GetID()
s.listed_names={13131313}
function s.initial_effect(c)
	-- 1. Self-Destruct without Umbra Witch
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_SELF_DESTROY)
	e1:SetCondition(s.descon)
	c:RegisterEffect(e1)

	-- 2. Triple Attack
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_EXTRA_ATTACK)
	e2:SetValue(2)
	c:RegisterEffect(e2)

	-- 3. Actlimit (Ancient Gear style)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetCode(EFFECT_CANNOT_ACTIVATE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(0,1)
	e3:SetCondition(s.actcon)
	e3:SetValue(1)
	c:RegisterEffect(e3)

	-- 4. Search Equip Spell on Grave Send
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_TO_GRAVE)
	e4:SetCountLimit(1,id)
	e4:SetTarget(s.thtg)
	e4:SetOperation(s.thop)
	c:RegisterEffect(e4)

	-- 5. Mandatory End Phase Destruction
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e5:SetCode(EVENT_PHASE+PHASE_END)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1)
	e5:SetOperation(s.selfdesop)
	c:RegisterEffect(e5)
end

s.SET_UMBRA_WITCH = 0x7f6
s.SET_INFERNAL_DEMON = 0x704
s.CARD_BAYONETTA = 13131313

-- 1. Destruction Condition
function s.umfilter(c)
	return c:IsFaceup() and (c:IsSetCard(s.SET_UMBRA_WITCH) or c:IsCode(s.CARD_BAYONETTA, 13131316))
end
function s.descon(e)
	return not Duel.IsExistingMatchingCard(s.umfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end

-- 3. Actlimit Condition
function s.actcon(e)
	return Duel.GetAttacker()==e:GetHandler()
end

-- 4. Search Logic
function s.thfilter(c)
	return c:IsType(TYPE_EQUIP) and c:IsAbleToHand() and c:ListsCode(s.CARD_BAYONETTA)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- 5. End Phase Destruction
function s.selfdesop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Destroy(e:GetHandler(),REASON_EFFECT)
end