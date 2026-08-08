--<Limit Breaker> Aurora Volentis
local s,id=GetID()
function s.initial_effect(c)
	-- Enable Pendulum and Fusion Attributes
	Pendulum.AddProcedure(c)
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,s.matfilter,s.matfilter)

	-- ==========================================
	-- PENDULUM EFFECT
	-- ==========================================
	-- Destroy card(s) added from Deck to opponent's hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_TO_HAND)
	e1:SetRange(LOCATION_PZONE)
	e1:SetCountLimit(1)
	e1:SetCondition(s.descon)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)

	-- ==========================================
	-- MONSTER EFFECTS
	-- ==========================================
	-- On Fusion Summon: Look at opp hand, place 1 on top of Deck
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.hdcon)
	e2:SetTarget(s.hdtg)
	e2:SetOperation(s.hdop)
	c:RegisterEffect(e2)

	-- Quick Effect: Respond to opp card/effect -> Move to P-Zone & SS 1 WATER Warrior from hand/Extra Deck
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+100)
	e3:SetCondition(s.pzcon)
	e3:SetTarget(s.pztg)
	e3:SetOperation(s.pzop)
	c:RegisterEffect(e3)
end

-- Material Filter: 2 Warrior Fusion Monsters
function s.matfilter(c,fc,sumtype,tp)
	return c:IsType(TYPE_FUSION,fc,sumtype,tp) and c:IsRace(RACE_WARRIOR,fc,sumtype,tp)
end

-- ==========================================
-- Pendulum Effect Logic
-- ==========================================
function s.desfilter(c,tp)
	return c:IsControler(1-tp) and c:IsPreviousLocation(LOCATION_DECK)
end

function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetCurrentPhase()~=PHASE_DRAW 
		and not Duel.IsDamageCalculated() 
		and eg:IsExists(s.desfilter,1,nil,tp)
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=eg:Filter(s.desfilter,nil,tp)
	if chk==0 then return #g>0 end
	Duel.SetTargetCard(g)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end

-- ==========================================
-- Fusion Summon Hand Control Logic
-- ==========================================
function s.hdcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

function s.hdtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(tp,0,LOCATION_HAND)>0 end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,1-tp,LOCATION_HAND)
end

function s.hdop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
	if #g>0 then
		Duel.ConfirmCards(tp,g)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local sg=g:Select(tp,1,1,nil)
		if #sg>0 then
			Duel.SendtoDeck(sg,nil,SEQ_DECKTOP,REASON_EFFECT)
		end
		Duel.ShuffleHand(1-tp)
	end
end

-- ==========================================
-- Quick Effect Pendulum Place & SS Logic (Fixed)
-- ==========================================
function s.pzcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
end

function s.spwaterfilter(c,e,tp,sc)
	if not (c:IsAttribute(ATTRIBUTE_WATER) and c:IsRace(RACE_WARRIOR) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)) then 
		return false 
	end
	if c:IsLocation(LOCATION_HAND) then
		-- Checking space in MMZ accounting for sc leaving the MZONE
		return Duel.GetMZoneCount(tp,sc)>0
	elseif c:IsLocation(LOCATION_EXTRA) and c:IsFaceup() then
		-- Checking EMZ/Linked MMZ space accounting for sc leaving the MZONE
		return Duel.GetLocationCountFromEx(tp,tp,sc,c)>0
	end
	return false
end

function s.pztg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.CheckPendulumZones(tp)
		and Duel.IsExistingMatchingCard(s.spwaterfilter,tp,LOCATION_HAND+LOCATION_EXTRA,0,1,nil,e,tp,c) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_EXTRA)
end

function s.pzop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not Duel.CheckPendulumZones(tp) then return end
	if Duel.MoveToField(c,tp,tp,LOCATION_PZONE,POS_FACEUP,true) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		-- After moving to PZONE, sc is no longer on MZONE, pass nil for zone calculations
		local g=Duel.SelectMatchingCard(tp,s.spwaterfilter,tp,LOCATION_HAND+LOCATION_EXTRA,0,1,1,nil,e,tp,nil)
		if #g>0 then
			Duel.BreakEffect()
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end