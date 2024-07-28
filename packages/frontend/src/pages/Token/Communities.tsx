/* eslint-disable prettier/prettier */
/* eslint-disable import/no-unused-modules */
import { zodResolver } from '@hookform/resolvers/zod'
import { useCallback } from 'react'
import { useForm } from 'react-hook-form'
import { PrimaryButton } from 'src/components/Button'
import Input from 'src/components/Input'
import Box from 'src/theme/components/Box'
import { Column } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { z } from 'zod'

import * as styles from './style.css'

// zod schemes
const schema = z.object({
    website: z.string().url().optional(),
    telegram: z.string().regex(/^https?:\/\/(t\.me|telegram\.me)\/[a-zA-Z0-9_]{5,}$/),
    twitter: z.string().regex(/^https?:\/\/(twitter\.com|x\.com)\/[a-zA-Z0-9_]{1,15}$/),
    discord: z.string().regex(/^https?:\/\/(discord\.gg|discord\.com\/invite)\/[a-zA-Z0-9-]+$/),
})

export default function Communities() {
    const {
        register,
        handleSubmit,
        setValue,
        formState: { errors },
    } = useForm<z.infer<typeof schema>>({
        resolver: zodResolver(schema),
    })

    const setCommunities = useCallback(async (data: z.infer<typeof schema>) => {
        console.log('data: ', data)
    }, [])

    return (
        <Column gap="32">
            <Text.Custom color="text2" fontWeight="normal" fontSize="24">
                Website and Communities
            </Text.Custom>
            <Column as="form" onSubmit={handleSubmit(setCommunities)} gap="24">
                <Column gap="8">
                    <Text.Body className={styles.inputLabel}>Website</Text.Body>

                    <Input placeholder="https://unruggable.meme" {...register('website')} />

                    <Box className={styles.errorContainer}>
                        {errors.website?.message ? <Text.Error>{errors.website.message}</Text.Error> : null}
                    </Box>
                </Column>

                <Column gap="8">
                    <Text.Body className={styles.inputLabel}>Telegram</Text.Body>

                    <Input placeholder="https://t.me/unruggable" {...register('telegram')} />

                    <Box className={styles.errorContainer}>
                        {errors.telegram?.message ? <Text.Error>{errors.telegram.message}</Text.Error> : null}
                    </Box>
                </Column>

                <Column gap="8">
                    <Text.Body className={styles.inputLabel}>Twitter / X</Text.Body>

                    <Input placeholder="https://x.com/unruggable" {...register('twitter')} />

                    <Box className={styles.errorContainer}>
                        {errors.twitter?.message ? <Text.Error>{errors.twitter.message}</Text.Error> : null}
                    </Box>
                </Column>

                <Column gap="8">
                    <Text.Body className={styles.inputLabel}>Discord</Text.Body>

                    <Input placeholder="https://discord.gg/unruggable" {...register('discord')} />

                    <Box className={styles.errorContainer}>
                        {errors.discord?.message ? <Text.Error>{errors.discord.message}</Text.Error> : null}
                    </Box>
                </Column>

                <PrimaryButton type="submit">
                    Submit
                </PrimaryButton>
            </Column>
        </Column>
    )
}