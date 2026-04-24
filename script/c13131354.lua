local s,id=GetID()

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- Fusion Materials
	Fusion.AddProcMix(c,true,true,13131313,13131318)

	-- Name becomes Bayonetta
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e0:SetCode(EFFECT_CHANGE_CODE)
	e0:SetRange(LOCATION_MZONE)
	e0:SetValue(13131313)
	c:RegisterEffect(e0)

	-- Cannot be destroyed by effects
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	-- On Fusion Summon: declare Spell/Trap and destroy
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.descon)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)

	-- End Phase (FIELD)
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e3:SetCode(EVENT_PHASE+PHASE_END)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+100)
	e3:SetCondition(s.epcon)
	e3:SetTarget(s.rettg)
	e3:SetOperation(s.retop)
	c:RegisterEffect(e3)

	-- End Phase (GY)
	local e4=e3:Clone()
	e4:SetRange(LOCATION_GRAVE)
	c:RegisterEffect(e4)
end

-- Archetype
s.UMBRA_WITCH=0x7f6

-- =========================
-- DESTROY EFFECT
-- =========================
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local op=Duel.SelectOption(tp,aux.Stringid(id,0),aux.Stringid(id,1))
	-- 0 = Spell, 1 = Trap

	local g=Group.CreateGroup()

	-- Opponent hand (no reveal)
	local hg=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
	for tc in aux.Next(hg) do
		if (op==0 and tc:IsType(TYPE_SPELL)) or (op==1 and tc:IsType(TYPE_TRAP)) then
			g:AddCard(tc)
		end
	end

	-- Opponent field
	local sg=Duel.GetMatchingGroup(function(c)
		return (op==0 and c:IsType(TYPE_SPELL)) or (op==1 and c:IsType(TYPE_TRAP))
	end,tp,0,LOCATION_ONFIELD,nil)

	g:Merge(sg)

	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end

-- =========================
-- END PHASE EFFECT (FIXED)
-- =========================
function s.epcon(e,tp,eg,ep,ev,re,r,rp)
	return true -- ensures trigger always checks
end

function s.spfilter3(c,e,tp)
	return c:IsSetCard(s.UMBRA_WITCH)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.rettg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		local canReturn =
			(c:IsLocation(LOCATION_MZONE) and c:IsAbleToExtra()) or
			(c:IsLocation(LOCATION_GRAVE) and c:IsAbleToDeck())

		return canReturn
			and Duel.IsExistingMatchingCard(s.spfilter3,tp,LOCATION_GRAVE,0,1,nil,e,tp)
	end

	Duel.SetOperationInfo(0,CATEGORY_TODECK,c,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end

function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end

	local sent=false

	if c:IsLocation(LOCATION_MZONE) then
		sent=Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0
	elseif c:IsLocation(LOCATION_GRAVE) then
		sent=Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0
	end

	if sent then
		Duel.BreakEffect()

		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local tc=Duel.SelectMatchingCard(tp,s.spfilter3,tp,LOCATION_GRAVE,0,1,1,nil,e,tp):GetFirst()
		if tc then
			Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end