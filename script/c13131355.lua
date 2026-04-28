local s,id=GetID()

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- Fusion Materials
	Fusion.AddProcMix(c,true,true,13131313,13131325)

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

	-- On Fusion Summon: Equip from opponent Deck
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_EQUIP+CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCondition(s.eqcon)
	e2:SetCountLimit(1,id)
	e2:SetOperation(s.eqop)
	c:RegisterEffect(e2)

	-- End Phase recycle (both turns)
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e3:SetCode(EVENT_PHASE+PHASE_END)
	e3:SetRange(LOCATION_MZONE+LOCATION_GRAVE)
	e3:SetCountLimit(1,id+100)
	e3:SetTarget(s.rettg)
	e3:SetOperation(s.retop)
	c:RegisterEffect(e3)
end

-- Archetype
s.UMBRA_WITCH=0x7f6

-- =========================
-- EQUIP FROM TOP DECK
-- =========================
function s.eqcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local p=1-tp

	if Duel.GetFieldGroupCount(p,LOCATION_DECK,0)==0 then return end

	local g=Duel.GetDecktopGroup(p,5)
	if #g==0 then return end

	Duel.ConfirmCards(tp,g)

	local mg=Group.CreateGroup()
	local ft=Duel.GetLocationCount(tp,LOCATION_SZONE)

	for tc in aux.Next(g) do
		if ft>0 and tc:IsMonster() then
			if Duel.Equip(tp,tc,c) then
				ft=ft-1

				-- Treat as Equip Spell
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_CHANGE_TYPE)
				e1:SetValue(TYPE_EQUIP+TYPE_SPELL)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e1)

				-- Equip limit
				local e2=Effect.CreateEffect(c)
				e2:SetType(EFFECT_TYPE_SINGLE)
				e2:SetCode(EFFECT_EQUIP_LIMIT)
				e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
				e2:SetValue(function(e,cc) return cc==e:GetLabelObject() end)
				e2:SetLabelObject(c)
				e2:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e2)

				mg:AddCard(tc)
			end
		else
			Duel.SendtoGrave(tc,REASON_EFFECT)
		end
	end

	-- ATK/DEF gain
	if #mg>0 and c:IsFaceup() then
		local atk=0
		local def=0

		for tc in aux.Next(mg) do
			local batk=tc:GetBaseAttack()
			local bdef=tc:GetBaseDefense()

			if batk<0 then batk=0 end
			if bdef<0 then bdef=0 end

			atk=atk+batk
			def=def+bdef
		end

		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_UPDATE_ATTACK)
		e2:SetValue(atk)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e2)

		local e3=e2:Clone()
		e3:SetCode(EFFECT_UPDATE_DEFENSE)
		e3:SetValue(def)
		c:RegisterEffect(e3)
	end

	Duel.ShuffleDeck(p)
end

-- =========================
-- END PHASE (BOTH TURNS)
-- =========================
function s.spfilter(c,e,tp)
	return c:IsSetCard(s.UMBRA_WITCH)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.rettg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return c:IsAbleToExtra()
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,c,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end

function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end

	if Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
		Duel.BreakEffect()

		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local tc=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp):GetFirst()
		if tc then
			Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end