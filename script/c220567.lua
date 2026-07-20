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
	e1:SetCode(EFFECT_INDESTRUCTABLE_COUNT)
	e1:SetRange(LOCATION_SZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.indtg)
	e1:SetValue(s.indct)
	c:RegisterEffect(e1)
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

function s.indct(e,re,r,rp)
	if (r&REASON_EFFECT)~=0 then
		return 1
	end
	return 0
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
			Duel.SkipPhase(p,PHASE_DRAW,RESET_PHASE|PHASE_END,2)
			Duel.SkipPhase(p,PHASE_MAIN1,RESET_PHASE|PHASE_END,2)
			Duel.SkipPhase(p,PHASE_MAIN2,RESET_PHASE|PHASE_END,2)
			Duel.SkipPhase(1-p,PHASE_DRAW,RESET_PHASE|PHASE_END,1)
			Duel.SkipPhase(1-p,PHASE_MAIN1,RESET_PHASE|PHASE_END,1)
			Duel.SkipPhase(1-p,PHASE_BATTLE,RESET_PHASE|PHASE_END,1,1)
			Duel.SkipPhase(1-p,PHASE_MAIN2,RESET_PHASE|PHASE_END,1)
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
			be:SetReset(RESET_PHASE+PHASE_MAIN1,2)
			Duel.RegisterEffect(be,tp)
			Duel.SkipPhase(1-p,PHASE_MAIN2,RESET_PHASE|PHASE_END,1)
			Duel.SkipPhase(1-p,PHASE_END,RESET_PHASE|PHASE_END,1)

						------------------------------------------------
						-- Opponent takes no damage
						------------------------------------------------

						local e1=Effect.GlobalEffect()
						e1:SetType(EFFECT_TYPE_FIELD)
						e1:SetCode(EFFECT_CHANGE_DAMAGE)
						e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
						e1:SetTargetRange(0,1)
						e1:SetValue(0)
						e1:SetReset(RESET_PHASE|PHASE_BATTLE)
						Duel.RegisterEffect(e1,tp)
						local e2=e1:Clone()
						e2:SetCode(EFFECT_NO_EFFECT_DAMAGE)
						Duel.RegisterEffect(e2,tp)
						
			end
	end
	
end