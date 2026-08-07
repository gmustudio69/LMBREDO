--<Limit Breaker> Glaciel
local s,id=GetID()
function s.initial_effect(c)
	-- Enable Pendulum Feature
	Pendulum.AddProcedure(c)

	-- ==========================================
	-- PENDULUM EFFECT
	-- ==========================================
	-- Place "<Limit Breaker> Ann" in Pendulum Zone
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_PZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(function(e) return e:GetHandler():HasFlagEffect(id) end)
	e1:SetTarget(s.pentg)
	e1:SetOperation(s.penop)
	c:RegisterEffect(e1)

	-- Track activation turn for Pendulum Zone
	local e_track=Effect.CreateEffect(c)
	e_track:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e_track:SetCode(EVENT_CUSTOM+id)
	c:RegisterEffect(e_track)

	-- ==========================================
	-- MONSTER EFFECTS
	-- ==========================================
	-- Alternative Special Summon Procedure from Face-up Extra Deck
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_SPSUMMON_PROC)
	e2:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e2:SetRange(LOCATION_EXTRA)
	e2:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	-- Quick Effect: Target & Destroy 1 card, look at 2 random hand cards, place 1 on top of Deck
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_DESTROY+CATEGORY_TODECK)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_END_PHASE)
	e3:SetCountLimit(1)
	e3:SetTarget(s.destg)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)
end

-- ==========================================
-- Definitions & Setcodes
-- ==========================================
local SET_LIMIT_BREAKER = 0xf86	  -- Replace with your actual "Limit Breaker" setcode
local CARD_ANN		   = 220414 -- Replace with exact ID of "<Limit Breaker> Ann"

-- ==========================================
-- Pendulum Effect Logic
-- ==========================================

function s.penfilter(c)
	return c:IsCode(CARD_ANN) and not c:IsForbidden()
end

function s.pentg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckPendulumZones(tp)
		and Duel.IsExistingMatchingCard(s.penfilter,tp,LOCATION_DECK,0,1,nil) end
end

function s.penop(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.CheckPendulumZones(tp) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local g=Duel.SelectMatchingCard(tp,s.penfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.MoveToField(g:GetFirst(),tp,tp,LOCATION_PZONE,POS_FACEUP,true)
	end
end

-- ==========================================
-- Alternative Special Summon Logic
-- ==========================================
function s.selfspconfilter(c)
	return c:IsSetCard(SET_LIMIT_BREAKER) and c:IsType(TYPE_MONSTER) and c:IsAbleToGraveAsCost()
end

function s.spcon(e,c)
	if c==nil then return true end
	local tp=e:GetHandlerPlayer()
	local g=Duel.GetMatchingGroup(s.selfspconfilter,tp,LOCATION_EXTRA,0,nil,c)
	return #g>0 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local c=e:GetHandler()
	local rg=Duel.GetMatchingGroup(s.selfspconfilter,tp,LOCATION_EXTRA,0,nil,c)
	local g=aux.SelectUnselectGroup(rg,e,tp,1,1,aux.ChkfMMZ(1),1,tp,HINTMSG_TOGRAVE,nil,nil,true)
	if #g>0 then
		g:KeepAlive()
		e:SetLabelObject(g)
		return true
	end
	return false
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if not g then return end
	Duel.SendtoGrave(g,REASON_COST)

	-- SS Restrict: Cannot SS from Extra Deck for rest of turn except Fusion and Link
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,3))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return c:IsLocation(LOCATION_EXTRA) and not (c:IsType(TYPE_FUSION) or c:IsType(TYPE_LINK))
end

-- ==========================================
-- Quick Effect Logic
-- ==========================================
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
		if #hand>0 then
			Duel.BreakEffect()
			-- Select up to 2 random cards from opponent's hand
			local count=math.min(#hand,2)
			local rg=hand:RandomSelect(tp,count)
			Duel.ConfirmCards(tp,rg)
			
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
			local sg=rg:Select(tp,1,1,nil)
			if #sg>0 then
				Duel.SendtoDeck(sg,nil,SEQ_DECKTOP,REASON_EFFECT)
			end
			Duel.ShuffleHand(1-tp)
		end
	end
end