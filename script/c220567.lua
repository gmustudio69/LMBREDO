--Pyre - Limit Break!!!
local s,id,o=GetID()
function s.initial_effect(c)
	-- Activate: Continuous Spell
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	-- Destruction protection
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetRange(LOCATION_SZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.indtg)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	-- Skip phase ignition effect
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1)
	e2:SetTarget(s.timetg)
	e2:SetOperation(s.timeop)
	c:RegisterEffect(e2)
end

function s.indtg(e,c)
	return c:IsAttribute(ATTRIBUTE_FIRE) and c:IsRace(RACE_WARRIOR)
end

function s.desfilter(c)
	return (c:IsAttribute(ATTRIBUTE_FIRE) and c:IsDefense(0) or c:IsSetCard(0x989))
		and c:IsDestructable()
		and (c:IsLocation(LOCATION_DECK) or c:IsLocation(LOCATION_HAND) or c:IsFaceup())
end

function s.timetg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.desfilter,tp,
			LOCATION_DECK|LOCATION_MZONE|LOCATION_SZONE,
			0,1,nil)
	end
end

function s.timeop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,s.desfilter,tp,LOCATION_DECK|LOCATION_MZONE|LOCATION_SZONE,0,1,1,nil)
	local tc=g:GetFirst()

	if not tc then return end
	if Duel.Destroy(tc,REASON_EFFECT)>0 then
		Duel.BreakEffect()
		if Duel.GetFlagEffect(tp,id+100)==0 and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
			Duel.RegisterFlagEffect(tp,id+100,0,0,1)
			local p=Duel.GetTurnPlayer()
			
			-- Phase skipping
			Duel.SkipPhase(p,PHASE_DRAW,RESET_PHASE|PHASE_END,2)
			Duel.SkipPhase(p,PHASE_MAIN1,RESET_PHASE|PHASE_END,2)
			Duel.SkipPhase(p,PHASE_BATTLE,RESET_PHASE|PHASE_END,1,1)
			Duel.SkipPhase(p,PHASE_MAIN2,RESET_PHASE|PHASE_END,2)
			Duel.SkipPhase(1-p,PHASE_DRAW,RESET_PHASE|PHASE_END,1)
			Duel.SkipPhase(1-p,PHASE_MAIN1,RESET_PHASE|PHASE_END,1)
			Duel.SkipPhase(1-p,PHASE_BATTLE,RESET_PHASE|PHASE_END,1,1)
			Duel.SkipPhase(1-p,PHASE_MAIN2,RESET_PHASE|PHASE_END,1)

			-- PREVENT ACTIVATIONS: Lock both players to Trigger Effects only
			local e_lock=Effect.GlobalEffect()
			e_lock:SetType(EFFECT_TYPE_FIELD)
			e_lock:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
			e_lock:SetCode(EFFECT_CANNOT_ACTIVATE)
			e_lock:SetTargetRange(1,1)
			e_lock:SetValue(s.actlimit)
			e_lock:SetReset(RESET_PHASE+PHASE_END,2)
			Duel.RegisterEffect(e_lock,tp)

			-- Battle phase locks
			local e1=Effect.GlobalEffect()
			e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
			e1:SetType(EFFECT_TYPE_FIELD)
			e1:SetCode(EFFECT_CANNOT_BP)
			e1:SetTargetRange(1,1)
			e1:SetReset(RESET_PHASE+PHASE_END,2)
			Duel.RegisterEffect(e1,tp)

			local be=Effect.GlobalEffect()
			be:SetType(EFFECT_TYPE_FIELD)
			be:SetCode(EFFECT_CANNOT_EP)
			be:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
			be:SetTargetRange(1,1)
			be:SetReset(RESET_PHASE+PHASE_MAIN1,3)
			Duel.RegisterEffect(be,tp)

			-- Opponent damage immunity
			local e_dam1=Effect.GlobalEffect()
			e_dam1:SetType(EFFECT_TYPE_FIELD)
			e_dam1:SetCode(EFFECT_CHANGE_DAMAGE)
			e_dam1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
			e_dam1:SetTargetRange(0,1)
			e_dam1:SetValue(0)
			Duel.RegisterEffect(e_dam1,tp)

			local e_dam2=e_dam1:Clone()
			e_dam2:SetCode(EFFECT_NO_EFFECT_DAMAGE)
			Duel.RegisterEffect(e_dam2,tp)

			-- Cleaner: Reset damage immunity after your next actual Battle Phase
			local e_clear=Effect.CreateEffect(e:GetHandler())
			e_clear:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
			e_clear:SetCode(EVENT_PHASE+PHASE_BATTLE)
			e_clear:SetLabel(tp)
			e_clear:SetCondition(function(eff,tplayer,eg,ep,ev,re,r,rp)
				return Duel.GetTurnPlayer() == eff:GetLabel()
			end)
			e_clear:SetOperation(function(eff,tplayer,eg,ep,ev,re,r,rp)
				e_dam1:Reset()
				e_dam2:Reset()
				eff:Reset()
			end)
			Duel.RegisterEffect(e_clear,tp)
		end
	end   
end

-- Filter: Allows only Mandatory and Optional Trigger Effects
function s.actlimit(e,re,tp)
	return true
end