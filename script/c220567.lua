--Card Name Placeholder (e.g., Pyrea Catalyst)
local s,id=GetID()
function s.initial_effect(c)
	-- Activate Spell
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)

	-- First time each FIRE Warrior would be destroyed by effect, it is not
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_DESTROY_SUBSTITUTE)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.subtg)
	e2:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
	e2:SetValue(s.subval)
	c:RegisterEffect(e2)

	-- Once per turn Main Phase trigger
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1)
	e3:SetTarget(s.destg)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)
end

-- Substitute Target: FIRE Warrior monsters
function s.subtg(e,c)
	return c:IsFaceup() and c:IsAttribute(ATTRIBUTE_FIRE) and c:IsRace(RACE_WARRIOR)
end
function s.subval(e,re,r,rp)
	if (r&REASON_EFFECT)~=0 then
		return 1
	else return 0 end
end

-- Filter for destruction: FIRE with 0 DEF OR "Pyrea" card
function s.desfilter(c)
	return (c:IsLocation(LOCATION_HAND+LOCATION_DECK) or c:IsFaceup()) 
		and ( (c:IsAttribute(ATTRIBUTE_FIRE) and c:GetDefense()==0) or c:IsSetCard(0xXXXX) ) -- Replace 0xXXXX with your actual "Pyrea" set code
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.desfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_ONFIELD,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_ONFIELD)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,s.desfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_ONFIELD,0,1,1,nil)
	if #g>0 and Duel.Destroy(g,REASON_EFFECT)>0 then
		-- Optional Once Per Duel choice
		if Duel.GetFlagEffect(tp,id)==0 and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
			Duel.RegisterFlagEffect(tp,id,0,0,1) -- Once per Duel mark
			
			-- 1. Apply: No Damage to Opponent
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_FIELD)
			e1:SetCode(EFFECT_CHANGE_DAMAGE)
			e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
			e1:SetTargetRange(0,1)
			e1:SetValue(0)
			Duel.RegisterEffect(e1,tp)
			local e2=e1:Clone()
			e2:SetCode(EFFECT_NO_EFFECT_DAMAGE)
			Duel.RegisterEffect(e2,tp)

			-- 2. Skip Current Turn's Main Phase 2
			local e3=Effect.CreateEffect(e:GetHandler())
			e3:SetType(EFFECT_TYPE_FIELD)
			e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
			e3:SetCode(EFFECT_SKIP_M2)
			e3:SetTargetRange(1,0)
			e3:SetReset(RESET_PHASE+PHASE_END)
			Duel.RegisterEffect(e3,tp)

			-- 3. Master Phase Interceptor (skips EVERYTHING until YOUR next Battle Phase actually occurs)
			local e4=Effect.CreateEffect(e:GetHandler())
			e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
			e4:SetCode(EVENT_PHASE_START+PHASE_DRAW) -- Listen at the very gate of every phase step
			e4:SetLabel(tp) -- Store who initiated the skip
			e4:SetCondition(s.skipcon)
			e4:SetOperation(s.skipop)
			Duel.RegisterEffect(e4,tp)
		end
	end
end

-- The dynamic phase skipper condition
function s.skipcon(e,tp,eg,ep,ev,re,r,rp)
	local initiator = e:GetLabel()
	local current_turn = Duel.GetTurnCount()
	local current_phase = Duel.GetCurrentPhase()
	local turn_player = Duel.GetTurnPlayer()

	-- If we have successfully navigated back to the Initiator's Battle Phase, kill this listener immediately
	if turn_player == initiator and current_phase == PHASE_BATTLE_START then
		e:Reset()
		return false
	end

	-- Skip conditions: Skip anything that isn't the initiator's Battle Phase
	return true
end

-- The dynamic phase skipper execution
function s.skipop(e,tp,eg,ep,ev,re,r,rp)
	local initiator = e:GetLabel()
	
	-- Command the engine to immediately skip whatever phase just attempted to start
	Duel.SkipPhase(Duel.GetTurnPlayer(), Duel.GetCurrentPhase(), RESET_PHASE+Duel.GetCurrentPhase(), 1)
	
	-- If we skip a phase that forces a turn shift (like End Phase), make sure the turn advances cleanly
	if Duel.GetCurrentPhase() == PHASE_END then
		Duel.TurnEnd()
	end
end