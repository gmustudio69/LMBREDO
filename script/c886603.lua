--<Limit Breaker> Solaris Frost
local s,id=GetID()
function s.initial_effect(c)
	-- Enable Pendulum and Fusion Attributes
	aux.EnablePendulumAttribute(c)
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,CARD_ANN,s.matfilter)

	-- ==========================================
	-- PENDULUM EFFECT
	-- ==========================================
	-- If card added to opp hand from Deck: Fusion Summon 1 Warrior Fusion Monster
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_TO_HAND)
	e1:SetRange(LOCATION_PZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.fuscon)
	e1:SetTarget(s.fustg)
	e1:SetOperation(s.fusop)
	c:RegisterEffect(e1)

	-- ==========================================
	-- MONSTER EFFECTS
	-- ==========================================
	-- Contact Fusion Procedure: Banish materials from Field/GY
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_SPSUMMON_PROC)
	e2:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e2:SetRange(LOCATION_EXTRA)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	-- If destroyed by card effect: Place in Pendulum Zone
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetCountLimit(1,id+100)
	e3:SetCondition(s.pencon2)
	e3:SetTarget(s.pentg2)
	e3:SetOperation(s.penop2)
	c:RegisterEffect(e3)

	-- Quick Effect: Destroy 1 card, look at 1 random opponent hand card, place on top of Deck
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_DESTROY+CATEGORY_TODECK)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_MZONE)
	e4:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	e4:SetCountLimit(1,id+200)
	e4:SetCondition(s.descon)
	e4:SetTarget(s.destg)
	e4:SetOperation(s.desop)
	c:RegisterEffect(e4)
end

-- ==========================================
-- Definitions & Setcodes
-- ==========================================
local CARD_ANN = 220414   -- Replace with exact ID of "<Limit Breaker> Ann"

function s.matfilter(c,fc,sumtype,tp)
	return c:IsAttribute(ATTRIBUTE_FIRE,fc,sumtype,tp) and c:IsRace(RACE_WARRIOR,fc,sumtype,tp)
end

-- ==========================================
-- Pendulum Fusion Logic
-- ==========================================
function s.fuscon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetCurrentPhase()~=PHASE_DRAW 
		and eg:IsExists(s.tohandfilter,1,nil,1-tp)
end

function s.tohandfilter(c,tp)
	return c:IsControler(tp) and c:IsPreviousLocation(LOCATION_DECK)
end

function s.mfilter(c,e)
	return c:IsCanBeFusionMaterial() and not c:IsImmuneToEffect(e)
end

function s.ffilter(c,e,tp,m,f,chkf)
	return c:IsType(TYPE_FUSION) and c:IsRace(RACE_WARRIOR) and (not f or f(c))
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false) 
		and m:IsExists(s.ffiltercheck,1,nil,c,e,tp,m,f,chkf)
end

function s.ffiltercheck(c,fc,e,tp,m,f,chkf)
	return fc:CheckFusionMaterial(m,c,chkf)
end

function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local mg=Duel.GetMatchingGroup(s.mfilter,tp,LOCATION_HAND+LOCATION_ONFIELD+LOCATION_PZONE,0,nil,e)
		return Duel.IsExistingMatchingCard(s.ffilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg,nil,0)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	local mg=Duel.GetMatchingGroup(s.mfilter,tp,LOCATION_HAND+LOCATION_ONFIELD+LOCATION_PZONE,0,nil,e)
	local sg=Duel.GetMatchingGroup(s.ffilter,tp,LOCATION_EXTRA,0,nil,e,tp,mg,nil,0)
	if #sg>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local tc=sg:Select(tp,1,1,nil):GetFirst()
		if tc then
			local mat=Duel.SelectFusionMaterial(tp,tc,mg,nil,0)
			tc:SetMaterial(mat)
			Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
			Duel.BreakEffect()
			Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
			tc:CompleteProcedure()
		end
	end
end

-- ==========================================
-- Contact Fusion / Banish Logic
-- ==========================================
function s.contactfilter1(c)
	return c:IsCode(CARD_ANN) and c:IsAbleToRemoveAsCost()
end

function s.contactfilter2(c)
	return c:IsAttribute(ATTRIBUTE_FIRE) and c:IsRace(RACE_WARRIOR) and c:IsAbleToRemoveAsCost()
end

function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local g1=Duel.GetMatchingGroup(s.contactfilter1,tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil)
	local g2=Duel.GetMatchingGroup(s.contactfilter2,tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil)
	return #g1>0 and #g2>0 and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local g1=Duel.GetMatchingGroup(s.contactfilter1,tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil)
	local g2=Duel.GetMatchingGroup(s.contactfilter2,tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil)
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local sg1=g1:Select(tp,1,1,nil)
	g2:RemoveCard(sg1:GetFirst())
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local sg2=g2:Select(tp,1,1,nil)
	sg1:Merge(sg2)
	
	if #sg1==2 then
		sg1:KeepAlive()
		e:SetLabelObject(sg1)
		return true
	end
	return false
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	local sg=e:GetLabelObject()
	if sg then
		Duel.Remove(sg,POS_FACEUP,REASON_COST)
	end
end

-- ==========================================
-- On Destruction -> Pendulum Zone
-- ==========================================
function s.pencon2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsReason(REASON_EFFECT) and c:IsPreviousLocation(LOCATION_MZONE)
end

function s.pentg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckPendulumZones(tp) end
end

function s.penop2(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.CheckPendulumZones(tp) then return end
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.MoveToField(c,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
	end
end

-- ==========================================
-- Quick Effect Destroy & Hand Control Logic
-- ==========================================
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase()
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() end
	if chk==0 then return Duel.IsExistingTarget(nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and Duel.Destroy(tc,REASON_EFFECT)>0 then
		local hand=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
		if #hand>0 and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
			Duel.BreakEffect()
			local rg=hand:RandomSelect(tp,1)
			Duel.ConfirmCards(tp,rg)
			Duel.SendtoDeck(rg,nil,SEQ_DECKTOP,REASON_EFFECT)
			Duel.ShuffleHand(1-tp)
		end
	end
end