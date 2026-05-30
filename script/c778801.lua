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

function s.matfilter(c,tp)
	return (c:IsSetCard(0x76b) and c:IsControler(tp))
		or (c:IsFacedown() and c:IsMonster())
end
function s.matcheck(g,tp)
	return #g==2
		and g:IsExists(function(c)
			return c:IsSetCard(0x76b) and c:IsControler(tp)
		end,1,nil)
		and g:IsExists(Card.IsFacedown,1,nil)
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()

	if Duel.GetLocationCountFromEx(tp,tp,nil,c)<=0 then
		return false
	end

	local g=Duel.GetMatchingGroup(
		s.matfilter,tp,
		LOCATION_MZONE,
		LOCATION_MZONE,
		nil,tp
	)

	return aux.SelectUnselectGroup(
		g,e,tp,2,2,
		function(sg) return s.matcheck(sg,tp) end,
		0
	)
end

function s.spfilter(c,tp)
	return s.mysthichfilter(c)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=Duel.GetMatchingGroup(
		s.matfilter,tp,
		LOCATION_MZONE,
		LOCATION_MZONE,
		nil,tp
	)

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)

	local sg=aux.SelectUnselectGroup(
		g,e,tp,2,2,
		function(g) return s.matcheck(g,tp) end,
		1,tp,HINTMSG_TOGRAVE
	)

	if not sg or #sg~=2 then return end

	local rg=sg:Filter(function(tc)
		return tc:IsSetCard(0x76b) and tc:IsFacedown()
	end,nil)

	if #rg>0 then
		Duel.ConfirmCards(1-tp,rg)
	end

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