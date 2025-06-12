-- Divine Arsenal G-4
local s, id, o = GetID()

function s.initial_effect(c)
	-- Chỉ cho phép 1 lá bài này trên sân.
	c:SetUniqueOnField(1, 0, id)

	-- Triệu hồi XYZ: Sử dụng 1+ quái thú Level 12.
	aux.AddXyzProcedure(c, nil, 12, 1, nil, nil, 99)
	c:EnableReviveLimit()

	-- Không thể bị Take Control
	local e0 = Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e0:SetRange(LOCATION_MZONE)
	e0:SetCode(EFFECT_CANNOT_CHANGE_CONTROL)
	e0:SetValue(1)
	c:RegisterEffect(e0)

	-- Hiệu ứng 1: Triệu hồi đặc biệt từ Extra Deck.
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCountLimit(1, id + EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	-- Hiệu ứng 2: Xáo trộn các lá bài bị banish về Deck.
	local e2 = Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_REMOVE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTarget(s.tdtg)
	e2:SetOperation(s.tdop)
	c:RegisterEffect(e2)

	-- Hiệu ứng 3: Giới hạn triệu hồi đặc biệt (chỉ cho phép quái thú tộc Máy).
	local e4 = Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetRange(LOCATION_MZONE + LOCATION_GRAVE)
	e4:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e4:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e4:SetTargetRange(1, 0)
	e4:SetTarget(s.splimit)
	c:RegisterEffect(e4)
end

-- Điều kiện triệu hồi đặc biệt từ Extra Deck: Kiểm tra có lá bài ID 220448 trên sân.
function s.filter(c)
	return c:IsCode(220448) and c:IsFaceup()
end

function s.spcon(e, c)
	if c == nil then return true end
	local tp = c:GetControler()
	return Duel.IsExistingMatchingCard(s.filter, tp, LOCATION_ONFIELD, 0, 1, nil)
end

-- Mục tiêu: Chọn các lá bài bị banish để xáo trộn về Deck.
function s.tdtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return eg:IsExists(Card.IsAbleToDeck, 1, nil)
	end
	Duel.SetOperationInfo(0, CATEGORY_TODECK, eg, eg:GetCount(), 0, 0)
end

-- Hành động: Xáo trộn các lá bài bị banish về Deck.
function s.tdop(e, tp, eg, ep, ev, re, r, rp)
	Duel.SendtoDeck(eg, nil, SEQ_DECKSHUFFLE, REASON_EFFECT)
end

-- Giới hạn triệu hồi đặc biệt: Chỉ quái thú tộc Máy.
function s.splimit(e, c, sump, sumtype, sumpos, targetp, se)
	return not c:IsRace(RACE_MACHINE)
end