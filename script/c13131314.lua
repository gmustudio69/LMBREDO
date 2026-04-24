local s,id=GetID()

function s.initial_effect(c)
	-- 1. Self-Destruction: No "Umbra Witch"
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EVENT_ADJUST)
	e1:SetCondition(s.sdcon)
	e1:SetOperation(s.sdop)
	c:RegisterEffect(e1)

	-- 2. Board Wipe: Special Summoned from GY (The Fixed Effect)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.descon)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)

	-- 3. Search: Sent to GY
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetCountLimit(1,id+100)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)

	-- 4. End Phase Self-Destruction
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EVENT_PHASE + PHASE_END)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1)
	e4:SetOperation(s.epop)
	c:RegisterEffect(e4)
end

-- IDs for reference
s.BAYONETTA_ID = 13131313 -- Updated based on your recent files
s.UMBRA_WITCH = 0x7f6

-- 1. Self-Destruction
function s.sdcon(e)
	return not Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard,s.UMBRA_WITCH),e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end
function s.sdop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Destroy(e:GetHandler(),REASON_EFFECT)
end

-- 2. Board Wipe (The problematic one)
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_GRAVE)
end

function s.desfilter(c,atk)
	-- Comparison works even if opponent is in Defense Position
	return c:IsFaceup() and c:GetAttack() < atk
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	-- Find Bayonetta by ID
	local bago=Duel.GetFirstMatchingCard(aux.FaceupFilter(Card.IsCode,s.BAYONETTA_ID),tp,LOCATION_MZONE,0,nil)
	
	if chk==0 then 
		if not bago then return false end
		return Duel.IsExistingMatchingCard(s.desfilter,tp,0,LOCATION_MZONE,1,nil,bago:GetAttack())
	end
	
	local g=Duel.GetMatchingGroup(s.desfilter,tp,0,LOCATION_MZONE,nil,bago:GetAttack())
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local bago=Duel.GetFirstMatchingCard(aux.FaceupFilter(Card.IsCode,s.BAYONETTA_ID),tp,LOCATION_MZONE,0,nil)
	if bago then
		local g=Duel.GetMatchingGroup(s.desfilter,tp,0,LOCATION_MZONE,nil,bago:GetAttack())
		if #g>0 then 
			Duel.Destroy(g,REASON_EFFECT) 
		end
	end
end

-- 3. Search logic
function s.thfilter(c)
	return c:IsRace(RACE_SPELLCASTER) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- 4. End Phase
function s.epop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Destroy(e:GetHandler(),REASON_EFFECT)
end