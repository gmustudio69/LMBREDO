--Floowandereeze & Wise
local s,id=GetID()
function s.initial_effect(c)
	-- Banish instead of leaving field
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e0:SetValue(LOCATION_REMOVED)
	c:RegisterEffect(e0)
	-- Protect other Floowandereeze monsters from destruction
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SET_POSITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e1:SetCondition(s.poscon)
	e1:SetTarget(s.postg)
	e1:SetValue(POS_FACEUP_ATTACK)
	c:RegisterEffect(e1)
	-- Search Floowandereeze Spell/Trap & Normal Summon
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.setcon)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
end
function s.poscon(e)
	return e:GetHandler():IsTributeSummoned()
end
function s.postg(e,c)
	return true
end

-- Set + additional Normal Summon
function s.setfilter(c)
	return c:IsSetCard(0x16f) and c:IsType(TYPE_SPELL+TYPE_TRAP)
end
function s.nsfilter(c)
	return c:IsSummonable(true,nil)
end
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsTributeSummoned()
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	-- Special Summon restriction
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(function(e,c) return true end)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)

	-- Search
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SSet(tp,g:GetFirst())
		-- Normal Summon immediately
		local sg=Duel.GetMatchingGroup(Card.IsSummonable,tp,LOCATION_HAND,0,nil,true,nil)
		if #sg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SUMMON)
			local sc=sg:Select(tp,1,1,nil):GetFirst()
			if sc then
				Duel.Summon(tp,sc,true,nil)
			end
		end
	end
end
