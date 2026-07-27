--Resonant <S> Victoria
local s,id=GetID()
function s.initial_effect(c)
	-- 1. Normal Summon: Draw 2, Shuffle 1 to Deck + Lock Deck/Extra Deck SS
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DRAW+CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.drtg)
	e1:SetOperation(s.drop)
	c:RegisterEffect(e1)

	-- 2. GY Destruction Replacement Effect
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EFFECT_DESTROY_REPLACE)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetTarget(s.reptg)
	e2:SetValue(s.repval)
	e2:SetOperation(s.repop)
	c:RegisterEffect(e2)
end

-- ==========================================
-- E1: Draw 2, Shuffle 1 + Summon Lock
-- ==========================================
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,2) end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(2)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_HAND)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	if Duel.Draw(p,d,REASON_EFFECT)==2 then
		Duel.ShuffleHand(tp)
		Duel.BreakEffect()
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local g=Duel.SelectMatchingCard(tp,Card.IsAbleToDeck,tp,LOCATION_HAND,0,1,1,nil)
		if #g>0 then
			Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
		end
	end

	-- Special Summon Lock: Only Psychic and Warrior from Deck or Extra Deck
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

function s.splimit(e,c,sump,sumtype,sumpos,target_p,se)
	-- Blocks SS from Deck or Extra Deck UNLESS it is Psychic or Warrior
	return (c:IsLocation(LOCATION_DECK) or c:IsLocation(LOCATION_EXTRA))
		and not (c:IsRace(RACE_PSYCHIC) or c:IsRace(RACE_WARRIOR))
end

-- ==========================================
-- E2: GY Destruction Replacement Logic
-- ==========================================
function s.lvl7warriorfilter(c)
	return c:IsFaceup() and c:IsRace(RACE_WARRIOR) 
		and ((c:IsLevelAbove(7) and c:IsType(TYPE_MONSTER)) or (c:IsRankAbove(7) and c:IsType(TYPE_XYZ)))
end

function s.repfilter(c,tp)
	return c:IsControler(tp) and c:IsOnField() and c:IsReason(REASON_EFFECT) and not c:IsReason(REASON_REPLACE)
end

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToRemove()
		and Duel.IsExistingMatchingCard(s.lvl7warriorfilter,tp,LOCATION_MZONE,0,1,nil)
		and eg:IsExists(s.repfilter,1,nil,tp) end
	return Duel.SelectEffectYesNo(tp,c,aux.Stringid(id,2))
end

function s.repval(e,c)
	return s.repfilter(c,e:GetHandlerPlayer())
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_EFFECT+REASON_REPLACE)
end