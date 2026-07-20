--Pyre - Limit Break!!!
local s,id=GetID()
function s.initial_effect(c)
	-- Activate: Continuous Spell
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)
	
	-- Destruction protection for FIRE Warrior
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_INDESTRUCTABLE_COUNT)
	e1:SetRange(LOCATION_SZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.indtg)
	e1:SetValue(s.indct)
	c:RegisterEffect(e1)
	
	-- Main Phase Destruction + Turn Skip
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1)
	e2:SetTarget(s.timetg)
	e2:SetOperation(s.timeop)
	c:RegisterEffect(e2)
end

-- Archetype code matching your "Pyrea" setup
function s.indtg(e,c)
	return c:IsAttribute(ATTRIBUTE_FIRE) and c:IsRace(RACE_WARRIOR)
end

function s.indct(e,re,r,rp)
	if (r&REASON_EFFECT)~=0 then
		return 1
	end
	return 0
end

function s.desfilter(c)
	return (c:IsAttribute(ATTRIBUTE_FIRE) and c:IsDefense(0) or c:IsSetCard(0x989))
		and c:IsDestructable()
		and (c:IsLocation(LOCATION_DECK|LOCATION_HAND) or c:IsFaceup())
end

function s.timetg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		-- Correctly maps hand, deck, and field locations
		return Duel.IsExistingMatchingCard(s.desfilter,tp,LOCATION_HAND|LOCATION_DECK|LOCATION_MZONE|LOCATION_SZONE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_HAND|LOCATION_DECK|LOCATION_MZONE|LOCATION_SZONE)
end

function s.timeop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,s.desfilter,tp,LOCATION_HAND|LOCATION_DECK|LOCATION_MZONE|LOCATION_SZONE,0,1,1,nil)
	local tc=g:GetFirst()
	if not tc then return end
	
	if Duel.Destroy(tc,REASON_EFFECT)>0 then
		-- Check hard Once per Duel restriction for the sub-effect
		if Duel.GetFlagEffect(tp,id)==0 and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
			Duel.RegisterFlagEffect(tp,id,0,0,1) -- Lock Once Per Duel flag
			
			local current_turn = Duel.GetTurnCount()
			
			-- 1. Create the system listener that handles ending turns/skipping phases cleanly
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
			e1:SetCode(EVENT_PREDRAW)
			e1:SetLabel(current_turn, 0) -- Label 1: Starting turn, Label 2: State manager tracking how many turns skipped
			e1:SetCondition(s.skipcon)
			e1:SetOperation(s.skipop)
			Duel.RegisterEffect(e1,tp)
			
			-- 2. Skip Main Phase 2 of this exact current turn safely
			local e_mp2=Effect.CreateEffect(e:GetHandler())
			e_mp2:SetType(EFFECT_TYPE_FIELD)
			e_mp2:SetCode(EFFECT_SKIP_M2)
			e_mp2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
			e_mp2:SetTargetRange(1,0)
			e_mp2:SetReset(RESET_PHASE+PHASE_END)
			Duel.RegisterEffect(e_mp2,tp)

			-- 3. Opponent takes NO damage (both battle and effect damage) until the jump ends
			local e_dmg1=Effect.CreateEffect(e:GetHandler())
			e_dmg1:SetType(EFFECT_TYPE_FIELD)
			e_dmg1:SetCode(EFFECT_CHANGE_DAMAGE)
			e_dmg1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
			e_dmg1:SetTargetRange(0,1)
			e_dmg1:SetValue(0)
			Duel.RegisterEffect(e_dmg1,tp)
			
			local e_dmg2=e_dmg1:Clone()
			e_dmg2:SetCode(EFFECT_NO_EFFECT_DAMAGE)
			Duel.RegisterEffect(e_dmg2,tp)
			
			-- 4. Clean up the damage immunity right after the next Battle Phase ends
			local e_clear=Effect.CreateEffect(e:GetHandler())
			e_clear:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
			e_clear:SetCode(EVENT_PHASE+PHASE_BATTLE)
			e_clear:SetLabelObject(e_dmg1)
			e_clear:SetLabel(tp) -- Save who the turn belongs to
			e_clear:SetCondition(s.clearcon)
			e_clear:SetOperation(function(e,tp,eg,ep,ev,re,r,rp)
				e_dmg1:Reset()
				e_dmg2:Reset()
				e:Reset()
			end)
			Duel.RegisterEffect(e_clear,tp)
			
			-- Instantly end the turn player's current turn right now
			Duel.SkipPhase(tp,PHASE_DRAW,RESET_PHASE+PHASE_END,1)
			Duel.SkipPhase(tp,PHASE_STANDBY,RESET_PHASE+PHASE_END,1)
			Duel.SkipPhase(tp,PHASE_MAIN1,RESET_PHASE+PHASE_END,1)
			Duel.SkipPhase(tp,PHASE_BATTLE,RESET_PHASE+PHASE_END,1)
			Duel.SkipPhase(tp,PHASE_MAIN2,RESET_PHASE+PHASE_END,1)
		end
	end   
end

-- Condition handling for the dynamic jump/skip state
function s.skipcon(e,tp,eg,ep,ev,re,r,rp)
	local start_turn, state = e:GetLabel()
	return Duel.GetTurnCount() ~= start_turn
end

function s.skipop(e,tp,eg,ep,ev,re,r,rp)
	local start_turn, state = e:GetLabel()
	
	-- state == 0 means we are handling the opponent's skipped turn
	if state == 0 then
		e:SetLabel(start_turn, 1) -- Shift tracker to next stage
		Duel.SkipPhase(Duel.GetTurnPlayer(),PHASE_DRAW,RESET_PHASE+PHASE_END,1)
		Duel.SkipPhase(Duel.GetTurnPlayer(),PHASE_STANDBY,RESET_PHASE+PHASE_END,1)
		Duel.SkipPhase(Duel.GetTurnPlayer(),PHASE_MAIN1,RESET_PHASE+PHASE_END,1)
		Duel.SkipPhase(Duel.GetTurnPlayer(),PHASE_BATTLE,RESET_PHASE+PHASE_END,1)
		Duel.SkipPhase(Duel.GetTurnPlayer(),PHASE_MAIN2,RESET_PHASE+PHASE_END,1)
		
	-- state == 1 means we are back on your turn; skip straight to Battle Phase
	elseif state == 1 then
		Duel.SkipPhase(tp,PHASE_DRAW,RESET_PHASE+PHASE_BATTLE_START,1)
		Duel.SkipPhase(tp,PHASE_STANDBY,RESET_PHASE+PHASE_BATTLE_START,1)
		Duel.SkipPhase(tp,PHASE_MAIN1,RESET_PHASE+PHASE_BATTLE_START,1)
		e:Reset() -- Task complete, drop the global turn skip hook
	end
end

-- Check if the current phase is your active Battle Phase ending to turn damage back on
function s.clearcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer() == e:GetLabel()
end