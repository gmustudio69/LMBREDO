local s,id=GetID()

function s.initial_effect(c)
	-- Link Summon
	Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsType,TYPE_EFFECT),2)
	c:EnableReviveLimit()
	-- Special Summon procedure from Extra Deck
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.spcon)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	-- If this card is Special Summoned
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)

	-- If this card is banished
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_LEAVE_GRAVE)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_REMOVE)
	e3:SetTarget(s.settg)
	e3:SetOperation(s.setop)
	c:RegisterEffect(e3)
end

function s.mysthichfilter(c)
	return c:IsSetCard(0x76b)
end

function s.fdfilter(c,exc)
	return c:IsFacedown() and c:IsMonster() and c~=exc
end

function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()

	if Duel.GetLocationCountFromEx(tp,tp,nil,c)<=0 then
		return false
	end

	local g=Duel.GetMatchingGroup(s.mysthichfilter,tp,LOCATION_MZONE,0,nil)

	for mc in aux.Next(g) do
		if Duel.IsExistingMatchingCard(
			s.fdfilter,tp,
			LOCATION_MZONE,LOCATION_MZONE,
			1,nil,mc
		) then
			return true
		end
	end

	return false
end

function s.spfilter(c,tp)
	return s.mysthichfilter(c)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g1=Duel.SelectMatchingCard(
		tp,
		s.mysthichfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		1,
		nil
	)

	local mc=g1:GetFirst()
	if not mc then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g2=Duel.SelectMatchingCard(
		tp,
		s.fdfilter,
		tp,
		LOCATION_MZONE,
		LOCATION_MZONE,
		1,
		1,
		nil,
		mc
	)

	local fc=g2:GetFirst()
	if not fc then return end

	if mc:IsFacedown() then
		Duel.ConfirmCards(1-tp,mc)
	end

	local sg=Group.FromCards(mc,fc)

	c:SetMaterial(sg)
	Duel.SendtoGrave(sg,REASON_MATERIAL+REASON_LINK)
end
-- Face-down monster count
function s.fdcountfilter(c)
	return c:IsFacedown() and c:IsMonster()
end

-- Destroy effect
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local ct=Duel.GetMatchingGroupCount(s.fdcountfilter,tp,
		LOCATION_MZONE,LOCATION_MZONE,nil)+1
	if chkc then
		return chkc:IsOnField() and chkc:IsSpellTrap()
	end
	if chk==0 then
		return ct>0 and Duel.IsExistingTarget(Card.IsSpellTrap,tp,
			LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,Card.IsSpellTrap,tp,
		LOCATION_ONFIELD,LOCATION_ONFIELD,1,ct,nil)

	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tg=Duel.GetTargetCards(e)
	if #tg>0 then
		Duel.Destroy(tg,REASON_EFFECT)
	end
end

-- Moon Spell
function s.spellfilter(c)
	return c:IsSetCard(0xaaf)
		and c:IsSpell()
		and c:IsSSetable()
end

-- Moon Trap
function s.trapfilter(c)
	return c:IsSetCard(0xaa)
		and c:IsTrap()
		and c:IsSSetable()
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>=2
			and Duel.IsExistingMatchingCard(s.spellfilter,tp,
				LOCATION_DECK,0,1,nil)
			and Duel.IsExistingMatchingCard(s.trapfilter,tp,
				LOCATION_DECK,0,1,nil)
	end
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<2 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g1=Duel.SelectMatchingCard(tp,s.spellfilter,tp,
		LOCATION_DECK,0,1,1,nil)
	if #g1==0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g2=Duel.SelectMatchingCard(tp,s.trapfilter,tp,
		LOCATION_DECK,0,1,1,nil)
	if #g2==0 then return end

	g1:Merge(g2)
	Duel.SSet(tp,g1)
end