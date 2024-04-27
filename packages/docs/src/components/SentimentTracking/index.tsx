import { TraceEvent } from '@uniswap/analytics'
import { useCallback, useState } from 'react'
import { Frown, Meh, Smile } from 'react-feather'
import styled, { css } from 'styled-components'

import { colors } from '../../theme/color'
import { Opacity } from '../../theme/style'
import {
  BrowserEvent,
  DocsSentiment,
  DocsSentimentSection,
  Sentiment,
  SharedEventName,
} from '../../utils/analyticsEvents'

const Container = styled.div`
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: center;
`

const FaceStyle = css<{ selected: boolean }>`
  cursor: pointer;
  opacity: ${({ selected }) => (selected ? Opacity.FULL : Opacity.MEDIUM)};
  ${({ selected }) => selected && 'color: #00000080;'}

  &:hover {
    opacity: ${() => Opacity.FULL};
    color: #00000080;
  }
`

const PositiveSentimentIcon = styled(Smile)<{ selected: boolean }>`
  fill: ${({ selected }) => (selected ? colors.greenVibrant : 'transparent')};

  &:hover {
    fill: ${colors.greenVibrant};
  }

  ${FaceStyle}
`

const NegativeSentimentIcon = styled(Frown)<{ selected: boolean }>`
  fill: ${({ selected }) => (selected ? colors.redVibrant : 'transparent')};
  opacity: ${({ selected }) => (selected ? Opacity.FULL : Opacity.MEDIUM)};

  &:hover {
    fill: ${colors.redVibrant};
  }

  ${FaceStyle}
`

const NeutralSentimentIcon = styled(Meh)<{ selected: boolean }>`
  fill: ${({ selected }) => (selected ? colors.yellowVibrant : 'transparent')};
  opacity: ${({ selected }) => (selected ? Opacity.FULL : Opacity.MEDIUM)};
  margin: 0 0.2rem;

  &:hover {
    fill: ${colors.yellowVibrant};
  }

  ${FaceStyle}
`

const StyledTextDiv = styled.div`
  font-size: 1rem;
  padding-right: 0.5rem;
`

export default function SentimentTracking({ analyticsSection }: { analyticsSection: DocsSentimentSection }) {
  const [selectedSentiment, setSelectedSentiment] = useState<null | Sentiment>(null)

  const isSentimentSelected = useCallback(
    (sentiment: Sentiment) => !!selectedSentiment && selectedSentiment === sentiment,
    [selectedSentiment],
  )

  return (
    <Container>
      <StyledTextDiv>Helpful?</StyledTextDiv>
      <TraceEvent
        element={DocsSentiment.POSITIVE_SENTIMENT}
        name={SharedEventName.SENTIMENT_SUBMITTED}
        events={[BrowserEvent.onClick]}
        section={analyticsSection}
      >
        <PositiveSentimentIcon
          selected={isSentimentSelected(Sentiment.POSITIVE)}
          onClick={() => {
            setSelectedSentiment(Sentiment.POSITIVE)
          }}
        />
      </TraceEvent>
      <TraceEvent
        element={DocsSentiment.NEUTRAL_SENTIMENT}
        name={SharedEventName.SENTIMENT_SUBMITTED}
        events={[BrowserEvent.onClick]}
        section={analyticsSection}
      >
        <NeutralSentimentIcon
          selected={isSentimentSelected(Sentiment.NEUTRAL)}
          onClick={() => {
            setSelectedSentiment(Sentiment.NEUTRAL)
          }}
        />
      </TraceEvent>
      <TraceEvent
        element={DocsSentiment.NEGATIVE_SENTIMENT}
        name={SharedEventName.SENTIMENT_SUBMITTED}
        events={[BrowserEvent.onClick]}
        section={analyticsSection}
      >
        <NegativeSentimentIcon
          selected={isSentimentSelected(Sentiment.NEGATIVE)}
          onClick={() => {
            setSelectedSentiment(Sentiment.NEGATIVE)
          }}
        />
      </TraceEvent>
    </Container>
  )
}
